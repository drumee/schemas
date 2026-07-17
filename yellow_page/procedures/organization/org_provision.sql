DELIMITER $

-- One-shot, TRANSACTIONAL organisation provisioning for the paid TEAM flow
-- (docs.drumee.com/technology/yellow-pages-schema). Folds the caller-side
-- sequence domain_create → domain_grant(dom_owner) → organisation_add into a
-- single atomic unit so a mid-failure can no longer leave orphaned domain
-- rows or a domain-less organisation.
--
-- Called by the Stripe webhook (checkout.session.completed with
-- metadata.entity_type='org') BEFORE payment_apply_entitlement, and safe to
-- re-enter: if the payer already owns an organisation (owner_id is UNIQUE)
-- the existing row is returned with already=1 and nothing is touched.
--
-- Product decisions baked in (2026-07-17):
--   • move-semantics membership: the payer's single yp.privilege row moves to
--     the new domain (domain_grant upsert), tier 63 = Remit.dom_owner
--     (@drumee/server-essentials lex/remit.js — JS is the tier authority).
--   • the payer's personal hubs MIGRATE into the org domain (hub_to_pro
--     pattern): hub.domain_id, their entity.dom_id, their vhost.dom_id and
--     vhost fqdn are rewritten under the organisation link.
--   • the payer's existing domain-1 quota row is re-keyed to the new domain
--     (create_organisation prior art) so usage cascades to the org tier.
--
-- NB: the legacy 30-day `subscription` insert from organisation_add is
-- deliberately NOT carried over — Stripe/yp.quota own entitlement now.
DROP PROCEDURE IF EXISTS `org_provision`$
CREATE PROCEDURE `org_provision`(
  IN _payer_id VARCHAR(16) CHARACTER SET ascii,
  IN _name     VARCHAR(512),
  IN _ident    VARCHAR(80)
)
proc: BEGIN
  DECLARE _domain_id   INT;
  DECLARE _domain_name VARCHAR(1000);
  DECLARE _org_id      VARCHAR(16) CHARACTER SET ascii;
  DECLARE _link        VARCHAR(1024);
  DECLARE _taken       INT DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  -- ── Idempotency: one organisation per owner ────────────────────────────
  SELECT id, domain_id FROM organisation WHERE owner_id = _payer_id LIMIT 1
    INTO _org_id, _domain_id;
  IF _org_id IS NOT NULL THEN
    SELECT o.*, 1 AS already FROM organisation o WHERE o.id = _org_id;
    LEAVE proc;
  END IF;

  SET _ident = LOWER(TRIM(_ident));
  SELECT CONCAT(_ident, '.', main_domain()) INTO _domain_name;

  -- ── Guards (outside the transaction — nothing written yet) ─────────────
  SELECT COUNT(*) INTO _taken FROM (
    SELECT id FROM entity       WHERE ident = _ident
    UNION
    SELECT id FROM organisation WHERE ident = _ident
    UNION
    SELECT id FROM vhost        WHERE fqdn  = _domain_name
    UNION
    SELECT CAST(id AS CHAR(16)) FROM domain WHERE name = _domain_name
  ) t;
  IF _taken > 0 THEN
    SELECT 'IDENT_NOT_AVAILABLE' AS error, _ident AS ident;
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- ── Domain (tenant pivot) ───────────────────────────────────────────────
  INSERT INTO domain (name) VALUES (_domain_name);
  SELECT id INTO _domain_id FROM domain WHERE name = _domain_name;

  -- ── Owner grant: privilege row + drumate/vhost/entity dom move ─────────
  -- 63 = Remit.dom_owner. Runs inside THIS transaction.
  CALL domain_grant(_domain_id, 63, _payer_id, 0);

  -- ── Organisation entity (organisation_add body, minus legacy pieces) ───
  SELECT id FROM yp.entity
    WHERE `type` = 'hub' AND area = 'pool'
      AND JSON_VALUE(settings, "$.pool_state") = "clean"
    LIMIT 1
  INTO _org_id;
  IF _org_id IS NULL THEN
    ROLLBACK;
    SELECT 'NO_POOL_ENTITY' AS error;
    LEAVE proc;
  END IF;

  SET _link = _domain_name;

  INSERT INTO organisation (`id`, `domain_id`, `name`, `link`, `ident`, `owner_id`, `metadata`)
  VALUES (
    _org_id, _domain_id, _name, _link, _ident, _payer_id,
    JSON_OBJECT(
      'ident', _ident, 'name', _name, 'link', _link,
      'domain_id', _domain_id, 'owner_id', _payer_id
    )
  );

  UPDATE entity SET
    `area`     = 'public',
    `dom_id`   = _domain_id,
    `type`     = 'organization',
    `status`   = 'active',
    `homepage` = ""
  WHERE id = _org_id;

  INSERT INTO yp.hub (`id`, `owner_id`, `origin_id`, `name`, `serial`, `hubname`, `domain_id`, `profile`)
  SELECT _org_id, _payer_id, _payer_id, _link, 9999999, NULL, _domain_id, NULL;

  INSERT INTO vhost (`fqdn`, `id`, `dom_id`)
  VALUES (_domain_name, _org_id, _domain_id);

  -- ── Migrate the payer's personal hubs into the org domain ──────────────
  -- (drumate_hub_to_pro pattern; the payer's own vhost was already moved by
  -- domain_grant, its fqdn is rewritten below with the other hub vhosts.)
  UPDATE yp.hub SET domain_id = _domain_id
    WHERE owner_id = _payer_id AND id != _org_id;

  UPDATE yp.entity SET dom_id = _domain_id
    WHERE id IN (SELECT id FROM yp.hub WHERE owner_id = _payer_id AND id != _org_id);

  UPDATE yp.vhost SET dom_id = _domain_id
    WHERE id IN (SELECT id FROM yp.hub WHERE owner_id = _payer_id AND id != _org_id);

  -- fqdn rule on a non-main domain is DASH, not dot — the org link is already
  -- a subdomain, so nesting another level is invalid. Matches both vhost
  -- factories: drumate_create (user: `<username>-u-<domain>` when domain !=
  -- main_domain()) and ensure_vhost (hub: CONCAT(hostname, '-', domain) when
  -- domain_id > 1). First labels are unique on the source domain, so the
  -- rewritten fqdns cannot collide inside the fresh org domain.
  UPDATE yp.vhost
    SET fqdn = CONCAT(SUBSTRING_INDEX(fqdn, '.', 1), '-', _link)
    WHERE dom_id = _domain_id AND id != _org_id;

  -- ── Re-key the payer's personal quota row to the new domain ────────────
  -- (create_organisation prior art; webhook's payment_apply_entitlement then
  -- upserts the org-tier quota keyed by this domain.)
  UPDATE quota SET domain_id = _domain_id
    WHERE payer_id = _payer_id AND domain_id = 1;

  COMMIT;

  SELECT o.*, 0 AS already FROM organisation o WHERE o.id = _org_id;
END$

DELIMITER ;
