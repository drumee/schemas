// One mail = one offer — the grant procs, driven against a real MariaDB.
//
// WHY A LIVE DATABASE and not a parser. Every behaviour here is a property of
// SQL semantics, not of text: ON DUPLICATE KEY UPDATE against a two-column
// unique index, the order guards fire in, what NOT EXISTS sees. A test that
// grepped the .sql files would pass against a proc that does the opposite.
//
// It builds its OWN schema from the repo files, so it is testing what would be
// deployed. `mkt_coupon_*` is not provisioned on a dev box (only
// mkt_campaign_link and reward_claim exist in the local `yp`), which is exactly
// why this cannot lean on an existing database.
//
// The scratch schema is utf8mb4_general_ci to match yp. If it drifts to
// unicode_ci the joins in these procs throw ERROR 1267.
const test = require("node:test");
const assert = require("node:assert/strict");
const { execFileSync } = require("node:child_process");
const { existsSync } = require("node:fs");
const { join } = require("node:path");

const ROOT = join(__dirname, "../..");
const DB = "scratch_grant_test";
const CAMPAIGN = "segment-a-101-contacts";
const CODE = "EMAILMKT270826_3";
const A = "huan@drumee.org";        // the addressee
const B = "someone.else@example.com";

const SOCKET = "/var/run/mysqld/mysqld.sock";
if (!existsSync(SOCKET)) {
  // Loud, not silent: a green run that tested nothing is worse than a red one.
  console.error(`\n  SKIPPED — no MariaDB socket at ${SOCKET}.`
    + "\n  These cases assert SQL semantics and cannot be faked.\n");
  process.exit(0);
}

const sql = (q, db = DB) => execFileSync("mysql",
  ["-N", "-B", `--database=${db}`, "-e", q], { encoding: "utf8" }).trim();
const file = (p, db = DB) => execFileSync("bash",
  ["-c", `mysql --database=${db} < ${JSON.stringify(join(ROOT, p))}`],
  { encoding: "utf8" });

/** One row of a CALL, as an object. Errors come back as {error: "..."}. */
function call(proc, ...args) {
  const lit = args.map((a) => (a === null ? "NULL"
    : typeof a === "number" ? String(a)
      : `'${String(a).replace(/'/g, "''")}'`)).join(", ");
  const out = execFileSync("mysql",
    ["-B", `--database=${DB}`, "-e", `CALL ${proc}(${lit})`],
    { encoding: "utf8" }).trim();
  const [head, row] = out.split("\n");
  if (!row) return {};
  const keys = head.split("\t");
  const vals = row.split("\t");
  return Object.fromEntries(keys.map((k, i) => [k, vals[i]]));
}

function reset({ requires_grant = 1, max_redemptions = "NULL" } = {}) {
  sql("DELETE FROM mkt_mail_grant; DELETE FROM mkt_coupon_redemption; "
    + "DELETE FROM mkt_coupon");
  sql("INSERT INTO mkt_coupon (code, partner, kind, plan_scope, percent_off,"
    + " duration_months, trial_days, active, max_redemptions, requires_grant,"
    + ` ctime, mtime) VALUES ('${CODE}','MKT','kol_discount','team',50,3,30,1,`
    + `${max_redemptions},${requires_grant},UNIX_TIMESTAMP(),UNIX_TIMESTAMP())`);
}

const tokenOf = (email = A) =>
  sql(`SELECT token FROM mkt_mail_grant WHERE email='${email}'`);

// ── build the schema from the repo ─────────────────────────────────────
test("setup", () => {
  sql(`DROP DATABASE IF EXISTS ${DB}; CREATE DATABASE ${DB} `
    + "DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci", "mysql");
  for (const p of [
    "yellow_page/tables/mkt_coupon.sql",
    "yellow_page/tables/mkt_coupon_redemption.sql",
    "yellow_page/tables/mkt_mail_grant.sql",
    "yellow_page/procedures/mkt/mkt_grant_issue.sql",
    "yellow_page/procedures/mkt/mkt_grant_claim.sql",
    "yellow_page/procedures/mkt/mkt_grant_resend.sql",
    "yellow_page/procedures/mkt/mkt_grant_revoke.sql",
    "yellow_page/procedures/mkt/mkt_coupon_reserve.sql",
    "yellow_page/procedures/mkt/mkt_coupon_validate.sql",
  ]) file(p);
  assert.equal(sql("SELECT COUNT(*) FROM information_schema.routines "
    + `WHERE routine_schema='${DB}'`), "6");
});

// ── THE SCENARIO the campaign asked for ────────────────────────────────
test("one mail, one open: the second click gets nothing", () => {
  reset();
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  assert.ok(g.token && !g.error, "the grant was not issued");

  // 1. click CTA, sign in as huan@drumee.org -> OPENS billing
  const first = call("mkt_grant_claim", g.token, A, "u001");
  assert.ok(!first.error, `first claim refused: ${first.error}`);
  assert.equal(first.code, CODE, "the coupon code was not revealed");
  assert.equal(first.percent_off, "50", "the offer shape did not travel");

  // 2. sign out, click the SAME CTA, sign in as the SAME account -> nothing
  const second = call("mkt_grant_claim", g.token, A, "u001");
  assert.equal(second.error, "OFFER_SPENT",
    "the link opened billing a second time — one mail bought two runs");
  assert.equal(second.code, undefined,
    "the code leaked on a refused claim");
});

test("single_use=0 lets the addressee come back", () => {
  reset();
  // The forgiving variant, for a campaign that opts out: they opened checkout,
  // went to find their card, came back.
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 0, 0, 0);
  assert.ok(!call("mkt_grant_claim", g.token, A, "u001").error);
  const second = call("mkt_grant_claim", g.token, A, "u001");
  assert.equal(second.code, CODE, "single_use=0 still burned the grant");
  assert.equal(sql(`SELECT claim_count FROM mkt_mail_grant WHERE email='${A}'`),
    "2", "claims are not being counted");
});

// ── THE INVARIANT ──────────────────────────────────────────────────────
test("a resend rotates the token — it cannot make a second grant", () => {
  reset();
  const first = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  // cooldown 1s, so the resend is allowed to proceed at all
  const again = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  assert.equal(sql("SELECT COUNT(*) FROM mkt_mail_grant"), "1",
    "a second grant row exists — one mail can now buy two deals");
  assert.notEqual(again.token, first.token, "the token was not rotated");
  assert.equal(again.send_count, "2", "send_count did not advance");
});

test("the OLD link dies the moment a new one is sent", () => {
  reset();
  const first = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  assert.equal(call("mkt_grant_claim", first.token, A, "u001").error,
    "OFFER_NOT_FOUND",
    "a forwarded copy of the FIRST mail still works after a resend");
});

test("a resend un-spends the grant — that is what it is for", () => {
  reset();
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  call("mkt_grant_claim", g.token, A, "u001");
  assert.equal(call("mkt_grant_claim", g.token, A, "u001").error, "OFFER_SPENT");
  const fresh = call("mkt_grant_resend", CAMPAIGN, A, "u001", 0, 0, 0);
  assert.ok(!fresh.error, `resend refused: ${fresh.error}`);
  assert.ok(!call("mkt_grant_claim", fresh.token, A, "u001").error,
    "the resent link does not work — the escape hatch is closed");
});

// ── who it belongs to ──────────────────────────────────────────────────
test("a forwarded link is worth nothing, and says nothing", () => {
  reset();
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  const stolen = call("mkt_grant_claim", g.token, B, "u002");
  assert.equal(stolen.error, "OFFER_NOT_YOURS");
  // An address-disclosure oracle would make a stolen link worth something.
  assert.ok(!Object.values(stolen).some((v) => String(v).includes("@")),
    "the refusal leaked the address the offer was written for");
  assert.equal(stolen.code, undefined, "the refusal leaked the coupon code");
  assert.equal(sql(`SELECT status FROM mkt_mail_grant WHERE email='${A}'`),
    "issued", "a stranger's failed claim spent the addressee's grant");
});

test("ownership is checked before expiry", () => {
  reset();
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  sql(`UPDATE mkt_mail_grant SET expires_at = UNIX_TIMESTAMP() - 10`);
  assert.equal(call("mkt_grant_claim", g.token, B, "u002").error,
    "OFFER_NOT_YOURS",
    "a stranger was told the link had EXPIRED — which confirms the address "
    + "behind it was a real recipient");
});

test("expired and revoked are refused, and named apart", () => {
  reset();
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  sql("UPDATE mkt_mail_grant SET expires_at = UNIX_TIMESTAMP() - 10");
  assert.equal(call("mkt_grant_claim", g.token, A, "u001").error,
    "OFFER_EXPIRED", "the UI cannot offer 'get a new one' without this name");

  reset();
  const h = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  call("mkt_grant_revoke", CAMPAIGN, A);
  assert.equal(call("mkt_grant_claim", h.token, A, "u001").error,
    "OFFER_REVOKED");
  assert.equal(call("mkt_grant_resend", CAMPAIGN, A, "u001", 0, 0, 0).error,
    "GRANT_REVOKED", "a resend revived a grant an admin had killed");
});

test("a dead coupon does not burn the grant", () => {
  reset();
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  sql(`UPDATE mkt_coupon SET active = 0 WHERE code = '${CODE}'`);
  assert.equal(call("mkt_grant_claim", g.token, A, "u001").error, "CODE_INACTIVE");
  assert.equal(sql(`SELECT status FROM mkt_mail_grant WHERE email='${A}'`),
    "issued",
    "the grant was spent on a switched-off coupon — one run gone for nothing, "
    + "and the holder has no reason to think they need a resend");
  // Fixing the coupon fixes the link, with no resend needed.
  sql(`UPDATE mkt_coupon SET active = 1 WHERE code = '${CODE}'`);
  assert.ok(!call("mkt_grant_claim", g.token, A, "u001").error);

  reset();
  const h = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  sql(`UPDATE mkt_coupon SET ends_at = UNIX_TIMESTAMP() - 10 WHERE code='${CODE}'`);
  assert.equal(call("mkt_grant_claim", h.token, A, "u001").error, "CODE_EXPIRED");
  assert.equal(sql(`SELECT status FROM mkt_mail_grant WHERE email='${A}'`),
    "issued", "an expired coupon burned the grant");
});

test("resend with no campaign takes the newest grant this address holds", () => {
  // The caller is a signed-in user looking at a refusal; they do not know a
  // campaign name, and letting them supply one would turn the button into a
  // way to ask for any offer in the table.
  reset();
  call("mkt_grant_issue", "older-campaign", CODE, A, "", 0, 1, 0, 0);
  sql("UPDATE mkt_mail_grant SET issued_at = issued_at - 1000");
  call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  const r = call("mkt_grant_resend", "", A, "u001", 0, 0, 0);
  assert.ok(!r.error, `resend refused: ${r.error}`);
  assert.equal(r.campaign, CAMPAIGN, "the older campaign was re-issued");
  assert.equal(sql("SELECT COUNT(*) FROM mkt_mail_grant"), "2",
    "the campaign-less resend created a row");
});

test("resend with no campaign and no grant refuses", () => {
  reset();
  assert.equal(call("mkt_grant_resend", "", B, "u002", 0, 0, 0).error,
    "GRANT_NOT_FOUND",
    "any signed-in account can mint itself an offer");
});

// ── resend limits ──────────────────────────────────────────────────────
test("the cooldown holds, then releases", () => {
  reset();
  call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 900);
  const hot = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 900);
  assert.equal(hot.error, "RESEND_COOLDOWN",
    "a click-happy user can mail-bomb their own inbox");
  assert.ok(Number(hot.retry_after) > 0, "no retry_after to show the user");
  // Age the last send past the window rather than sleeping.
  sql("UPDATE mkt_mail_grant SET last_sent_at = last_sent_at - 1000");
  assert.ok(!call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 900).error,
    "the cooldown never lets go");
});

test("send_count includes the first send, and stops at the limit", () => {
  reset();
  call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 3, 0);   // 1
  call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 3, 0);   // 2
  call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 3, 0);   // 3
  const over = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 3, 0);
  assert.equal(over.error, "RESEND_LIMIT",
    "the original send is not being counted — the user gets 4, not 3");
  assert.equal(over.send_count, "3");
});

test("resend refuses an address that was never mailed this campaign", () => {
  reset();
  assert.equal(call("mkt_grant_resend", CAMPAIGN, B, "u002", 0, 0, 0).error,
    "GRANT_NOT_FOUND",
    "any account can grant itself a campaign it was never part of");
});

test("resend does not let the caller name the coupon", () => {
  // The signature has no code parameter, so the button cannot be turned into
  // "issue me any code in the table".
  const params = sql("SELECT GROUP_CONCAT(parameter_name ORDER BY ordinal_position)"
    + " FROM information_schema.parameters WHERE specific_schema="
    + `'${DB}' AND specific_name='mkt_grant_resend'`);
  assert.ok(!/_code/.test(params), `resend takes a code: ${params}`);
});

// ── the reserve / validate gate ────────────────────────────────────────
const RES = (email) =>
  call("mkt_coupon_reserve", CODE, email, "u001", "team", "monthly", "org", "", 0);
const VAL = (email) => call("mkt_coupon_validate", CODE, email, "team", 0);

test("requires_grant: no claimed grant, no redemption", () => {
  reset({ requires_grant: 1 });
  assert.equal(RES(A).error, "OFFER_NOT_GRANTED",
    "the code is still redeemable by anyone who learns it");
  assert.equal(VAL(A).error, "OFFER_NOT_GRANTED",
    "Apply green-lights a code Proceed will refuse");

  // An ISSUED but unclaimed grant is not enough: the claim is where identity
  // was actually checked.
  call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  assert.equal(RES(A).error, "OFFER_NOT_GRANTED",
    "an unclaimed grant passed the gate");
});

test("requires_grant: a claimed grant lets exactly its owner through", () => {
  reset({ requires_grant: 1 });
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  call("mkt_grant_claim", g.token, A, "u001");
  assert.ok(!VAL(A).error, `validate refused the owner: ${VAL(A).error}`);
  const r = RES(A);
  assert.ok(!r.error, `reserve refused the owner: ${r.error}`);
  assert.equal(r.status, "pending");
  // Someone who typed the code by hand, having read it over a shoulder.
  assert.equal(RES(B).error, "OFFER_NOT_GRANTED");
  assert.equal(VAL(B).error, "OFFER_NOT_GRANTED");
});

test("requires_grant=0 leaves every existing code exactly as it was", () => {
  reset({ requires_grant: 0 });
  const r = RES(A);
  assert.ok(!r.error, `an ungated code was refused: ${r.error}`);
  assert.ok(!VAL(A).error);
  assert.equal(sql("SELECT COUNT(*) FROM mkt_mail_grant"), "0",
    "the ungated path touched the grant table");
});

test("reserve and validate agree on every case", () => {
  // The two procs' own comments say they must not drift. This is that, driven
  // rather than read.
  const cases = [
    ["no grant", () => { reset({ requires_grant: 1 }); }, A],
    ["issued only", () => {
      reset({ requires_grant: 1 });
      call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
    }, A],
    ["claimed, wrong person", () => {
      reset({ requires_grant: 1 });
      const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
      call("mkt_grant_claim", g.token, A, "u001");
    }, B],
    ["revoked after claiming", () => {
      reset({ requires_grant: 1 });
      const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
      call("mkt_grant_claim", g.token, A, "u001");
      call("mkt_grant_revoke", CAMPAIGN, A);
    }, A],
    ["ungated", () => { reset({ requires_grant: 0 }); }, A],
  ];
  for (const [name, setup, email] of cases) {
    setup();
    const v = VAL(email).error || "OK";
    setup();                       // reserve WRITES, so rebuild the state
    const r = RES(email).error || "OK";
    assert.equal(v, r,
      `${name}: validate says ${v}, reserve says ${r} — the shopper is `
      + "told one thing at Apply and another at Proceed");
  }
});

test("a revoked grant closes the code again", () => {
  reset({ requires_grant: 1 });
  const g = call("mkt_grant_issue", CAMPAIGN, CODE, A, "", 0, 1, 0, 0);
  call("mkt_grant_claim", g.token, A, "u001");
  call("mkt_grant_revoke", CAMPAIGN, A);
  assert.equal(RES(A).error, "OFFER_NOT_GRANTED",
    "revoking a grant left the redemption path open");
});

test("teardown", () => {
  sql(`DROP DATABASE ${DB}`, "mysql");
});
