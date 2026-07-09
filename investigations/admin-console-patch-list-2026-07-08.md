# Admin Console — prod patch runbook

**Source:** đã apply + verify trên **stage** (`drumee.in`, 2026-07-08 → 2026-07-09)  
**Branch:** `feat/admin-console-audit-filter` → PR https://github.com/drumee/schemas/pull/50  
**Base:** `preview`

---

## Stage status (đã chạy)

| Check | Stage (`drumee.in`) |
|-------|---------------------|
| yp SPs (7) | ✅ có đủ |
| `action_log` enum `invite_sent`/`invite_accepted` | ✅ **813/813** |
| `get_hub_user_storage` | ✅ (~445 hub DBs) |
| `hub_get_audit_logs_window` + `_count` | ✅ (~1572 routines) |

→ List dưới đây = **cùng bộ file cần chạy trên prod**.

---

## Prod — list file cần patch (11)

### 1) `common` → mọi hub + drumate DB

| # | File | Mục đích |
|---|------|----------|
| 1 | `common/patches/alter_action_log_add_invite_actions.sql` | ALTER enum `action_log.action` (+ `invite_sent`, `invite_accepted`) |
| 2 | `common/procedures/action_log/hub_get_audit_logs_window.sql` | Audit log list + filter |
| 3 | `common/procedures/action_log/hub_get_audit_logs_count.sql` | Audit log count |

### 2) `yp`

| # | File | Mục đích |
|---|------|----------|
| 4 | `yellow_page/procedures/adminpannel/member_list_stats.sql` | Pending Invites counter |
| 5 | `yellow_page/procedures/adminpannel/member_list_hubs_by_domain.sql` | Target Resource (hub list) |
| 6 | `yellow_page/procedures/secure_share/secure_share_guest_events_by_domain.sql` | Guest activity list + search |
| 7 | `yellow_page/procedures/secure_share/secure_share_guest_events_by_domain_count.sql` | Guest activity count |
| 8 | `yellow_page/procedures/adminpannel/get_org_storage_stats.sql` | TOTAL HUB STORAGE |
| 9 | `yellow_page/procedures/adminpannel/get_org_user_storage.sql` | User Storage Distribution |
| 10 | `yellow_page/procedures/adminpannel/get_org_user_storage_count.sql` | User storage count |

### 3) `hub` → mọi hub DB

| # | File | Mục đích |
|---|------|----------|
| 11 | `hub/procedures/admin/get_hub_user_storage.sql` | Hub user storage roll-up |

### Enum `invite_sent` / `invite_accepted` — chạy cái nào?

| File | Khi nào | Trên prod DB đã có `action_log` |
|------|---------|--------------------------------|
| **`common/patches/alter_action_log_add_invite_actions.sql` (#1)** | **Bắt buộc** | ✅ Đây là lệnh bổ sung enum (`ALTER … MODIFY`) |
| `common/tables/action_log.sql` | Seed / DB mới | ❌ **Không chạy** — `CREATE TABLE IF NOT EXISTS` thấy bảng đã có thì **bỏ qua**, enum **không** đổi |
| `templates/factory/*.sql` | Factory tạo DB mới | Không patch runtime |

→ Muốn bổ sung enum trên prod = chạy **#1 ALTER**, không phải seed table.

---

## Prod — lệnh chạy

```bash
cd /path/to/schemas   # prod schemas checkout (branch đã merge / tag release)

# --- 1) common (hub + drumate) ---
node bin/patch.js --schemas=$PWD --source=common/patches/alter_action_log_add_invite_actions.sql --target=common --orphan=remove --force
node bin/patch.js --schemas=$PWD --source=common/procedures/action_log/hub_get_audit_logs_window.sql --target=common --orphan=remove --force
node bin/patch.js --schemas=$PWD --source=common/procedures/action_log/hub_get_audit_logs_count.sql --target=common --orphan=remove --force

# --- 2) yp ---
for f in \
  yellow_page/procedures/adminpannel/member_list_stats.sql \
  yellow_page/procedures/adminpannel/member_list_hubs_by_domain.sql \
  yellow_page/procedures/secure_share/secure_share_guest_events_by_domain.sql \
  yellow_page/procedures/secure_share/secure_share_guest_events_by_domain_count.sql \
  yellow_page/procedures/adminpannel/get_org_storage_stats.sql \
  yellow_page/procedures/adminpannel/get_org_user_storage.sql \
  yellow_page/procedures/adminpannel/get_org_user_storage_count.sql
do
  node bin/patch.js --schemas=$PWD --source=$f --target=yp --orphan=remove --force
done

# --- 3) hub ---
node bin/patch.js --schemas=$PWD --source=hub/procedures/admin/get_hub_user_storage.sql --target=hub --orphan=remove --force
```

### Follow-up bắt buộc sau ALTER (#1)

`patch.js --target=common` **chỉ** entity `type IN ('hub','drumate')`.  
Trên stage còn thiếu schema **orphan** + type **`organization`** → phải ALTER nốt:

```bash
# Verify còn thiếu invite enum
mysql -N -e "
SELECT
  SUM(COLUMN_TYPE LIKE '%invite_sent%') AS with_invite,
  SUM(COLUMN_TYPE NOT LIKE '%invite_sent%') AS missing,
  COUNT(*) AS total
FROM information_schema.COLUMNS
WHERE TABLE_NAME='action_log' AND COLUMN_NAME='action';
"

# Nếu missing > 0: ALTER mọi schema còn thiếu
mysql -N -e "
SELECT TABLE_SCHEMA
FROM information_schema.COLUMNS
WHERE TABLE_NAME='action_log' AND COLUMN_NAME='action'
  AND COLUMN_TYPE NOT LIKE '%invite_sent%';
" | while read db; do
  echo "ALTER $db"
  mysql -e "ALTER TABLE \`$db\`.action_log MODIFY action enum(
    'added','deleted','changed','left','removed','backup','connection',
    'grant_access','change_policy','share_link','create_workspace',
    'invite_sent','invite_accepted'
  ) DEFAULT NULL;"
done
```

### Verify sau patch (prod)

```bash
# yp
mysql -N yp -e "
SELECT ROUTINE_NAME FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA='yp' AND ROUTINE_NAME IN (
  'member_list_stats','member_list_hubs_by_domain',
  'secure_share_guest_events_by_domain','secure_share_guest_events_by_domain_count',
  'get_org_storage_stats','get_org_user_storage','get_org_user_storage_count'
);"

# action_log enum — expect missing=0
mysql -N -e "
SELECT
  SUM(COLUMN_TYPE LIKE '%invite_sent%') AS with_invite,
  SUM(COLUMN_TYPE NOT LIKE '%invite_sent%') AS missing,
  COUNT(*) AS total
FROM information_schema.COLUMNS
WHERE TABLE_NAME='action_log' AND COLUMN_NAME='action';
"

# hub SPs
mysql -N -e "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_NAME='get_hub_user_storage';"
mysql -N -e "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_NAME IN ('hub_get_audit_logs_window','hub_get_audit_logs_count');"
```

---

## Feature map (QA sau prod)

| Feature | Files |
|---------|-------|
| Pending Invites counter | #4 `member_list_stats.sql` |
| Audit filter + Target Resource | #1–3, #5 |
| Guest activity search | #6–7 |
| Storage TOTAL = User Distribution | #8–10 |
| Hub user storage roll-up | #11 |

---

## Enum mới → data audit: chuỗi phụ thuộc

Chỉ patch SQL **không** tạo row `invite_sent` / `invite_accepted`. Cần **cả write + read**:

```
Invite UI / signup
  → server-team hub.js | signup.js | butler.js
      writeAudit({ action: 'invite_sent' | 'invite_accepted', category: 'member', ... })
  → <hub_db>.hub_add_action_log (IN _action VARCHAR — không hardcode enum)
  → INSERT action_log  ← cần cột enum đã ALTER (#1)
  → admin-api get_audit_logs
  → hub_get_audit_logs_window / _count  (_action = '' OR a.action = _action)
  → admin-console audit.js filter keys invite_sent / invite_accepted
```

| Layer | Gắn enum mới? | Ghi chú |
|-------|---------------|---------|
| `#1` ALTER `action_log.action` | **Bắt buộc** | Không có → INSERT fail / silent audit fail |
| `hub_add_action_log` | Không cần đổi SP | `_action VARCHAR(16)` — nhận mọi string hợp lệ với cột |
| `hub_get_audit_logs_window` / `_count` | Không hardcode list | Filter động `a.action = _action` — FE/API truyền `invite_sent` là đủ |
| `hub_count_high_risk_actions` | **Không** gồm invite | Chỉ `grant_access/change_policy/share_link/removed` — invite không vào High-Risk card |
| **server-team** `hub.js` / `signup.js` / `butler.js` | **Bắt buộc deploy** | Đây mới **ghi** `invite_sent` / `invite_accepted` vào `action_log` |
| admin-console `audit.js` | Đã có filter keys | Chỉ hiện data nếu đã có row |
| `contact.js` `invite_sent` | Khác bảng | Ghi `contact_activity` qua `contact_log_activity` — **không** phải Admin Audit `action_log` |

### Gap đã thấy trên stage (`drumee.in` / endpoint `vudangnt`)

- Schema enum: ✅ 813/813
- Runtime `/srv/drumee/runtime/server/vudangnt/service/private/hub.js`: **0** chỗ `invite_sent` (cũ hơn `main` có 6)
- Hệ quả: invite vẫn tạo `pending_invitation` (Pending Invites count tăng), nhưng **Audit Logs không có** `invite_sent` cho đến khi deploy server-team có `writeAudit(... invite_sent/invite_accepted)`

**Prod checklist thêm (ngoài 11 SQL):**

1. Deploy **server-team** (ít nhất `service/private/hub.js`, `signup.js`, `butler.js`, `private/_audit.js`) có audit invite  
2. Patch SQL #1–3 (enum + audit read SPs)  
3. Deploy admin-console (filter UI) + admin-api nếu chưa  

---

## Manifest / changelog (repo)

Tất cả 11 file đã có trong `patches/manifest.txt` + `patches/changelog.txt` + `CHANGELOG.md` trên branch PR #50.
