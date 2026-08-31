#!/usr/bin/env bash
set -euo pipefail

db_name=${1:?usage: notification-v2-schema.sh <disposable-db>}
case "$db_name" in
  notification_v2_test_*) ;;
  *) echo "refusing non-test database: $db_name" >&2; exit 2 ;;
esac

sql() {
  mariadb --batch --skip-column-names "$db_name" -e "$1"
}

expect() {
  local label=$1
  local expected=$2
  local statement=$3
  local actual
  actual=$(sql "$statement")
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL $label: expected '$expected', got '$actual'" >&2
    exit 1
  fi
}

token_a='notification-test-token-a'
token_b='notification-test-token-b'
digest_a=$(printf '%s' "$token_a" | sha256sum | awk '{print $1}')
digest_b=$(printf '%s' "$token_b" | sha256sum | awk '{print $1}')

sql "CALL device_registration_v2('ntfytesta','token','$digest_a','$token_a','device-a','android',NULL,NULL,NULL)" >/dev/null
expect create 'ntfytesta	active	1	1' \
  "SELECT uid,state,binding_version,state_version FROM device_registration_v2 WHERE registration_digest='$digest_a'"

registration_id=$(sql "SELECT registration_id FROM device_registration_v2 WHERE registration_digest='$digest_a'")
sql "CALL device_registration_v2('ntfytesta','token','$digest_a','$token_a','device-a','android',NULL,NULL,NULL)" >/dev/null
expect idempotent-refresh 'ntfytesta	active	1	1' \
  "SELECT uid,state,binding_version,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"

sql "CALL device_registration_v2('ntfytestb','token','$digest_a','$token_a','device-b','ios',NULL,NULL,NULL)" >/dev/null
expect no-cas-rebind-blocked 'ntfytesta	1	1' \
  "SELECT uid,binding_version,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"

sql "CALL device_registration_v2('ntfytestb','token','$digest_a','$token_a','device-b','ios',$registration_id,1,1)" >/dev/null
expect account-switch 'ntfytestb	active	2	2' \
  "SELECT uid,state,binding_version,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"
expect account-switch-tombstone '1' \
  "SELECT COUNT(*) FROM device_registration_v2_tombstone WHERE registration_id=$registration_id AND uid='ntfytesta' AND reason='rebound'"

sql "CALL device_registration_v2_unregister('ntfytesta',$registration_id,1,1)" >/dev/null
expect stale-unregister-blocked 'ntfytestb	active	2	2' \
  "SELECT uid,state,binding_version,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"

expect list-current-recipient "$registration_id	ntfytestb	token	2	2" \
  "CALL push_registration_list('[\"ntfytesta\",\"ntfytestb\"]',0,500)"
expect get-wrong-recipient '' \
  "CALL push_registration_get($registration_id,'ntfytesta',2,2)"
expect get-current-recipient "$registration_id	ntfytestb	token	$token_a	2	2" \
  "CALL push_registration_get($registration_id,'ntfytestb',2,2)"

sql "CALL device_registration_v2_invalidate($registration_id,1,1)" >/dev/null
expect stale-invalidation-blocked 'active	2' \
  "SELECT state,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"

sql "CALL device_registration_v2_invalidate($registration_id,2,2)" >/dev/null
expect exact-invalidation 'inactive	2	3' \
  "SELECT state,binding_version,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"

sql "CALL device_registration_v2('ntfytestb','token','$digest_a','$token_a','device-b','ios',NULL,NULL,NULL)" >/dev/null
expect no-cas-reactivation-blocked 'inactive	3' \
  "SELECT state,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"

sql "CALL device_registration_v2('ntfytestb','token','$digest_a','$token_a','device-b','ios',$registration_id,2,3)" >/dev/null
expect exact-reactivation 'active	2	4' \
  "SELECT state,binding_version,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"

sql "CALL device_registration_v2('ntfytestb','token','$digest_b','$token_b','device-b','ios',$registration_id,2,4)" >/dev/null
expect token-rotation "$registration_id	ntfytestb	active	2	5" \
  "SELECT registration_id,uid,state,binding_version,state_version FROM device_registration_v2 WHERE registration_digest='$digest_b'"
expect old-digest-removed '0' \
  "SELECT COUNT(*) FROM device_registration_v2 WHERE registration_digest='$digest_a'"

sql "CALL device_registration_v2_unregister('ntfytestb',$registration_id,2,5)" >/dev/null
expect exact-unregister 'tombstoned	2	6' \
  "SELECT state,binding_version,state_version FROM device_registration_v2 WHERE registration_id=$registration_id"
expect no-send-after-unregister '' \
  "CALL push_registration_list('[\"ntfytestb\"]',0,500)"

sql "CALL device_registration_v2_unregister('ntfytestb',$registration_id,2,5)" >/dev/null
expect unregister-replay-single-tombstone '1' \
  "SELECT COUNT(*) FROM device_registration_v2_tombstone WHERE registration_id=$registration_id AND uid='ntfytestb' AND binding_version=2 AND state_version=5 AND reason='unregistered'"

sql "CREATE TABLE device_registation (device_id VARCHAR(200) PRIMARY KEY, uid VARCHAR(16), status VARCHAR(20)); INSERT INTO device_registation VALUES ('legacy-device','ntfytestb','active')"
expect legacy-excluded '' \
  "CALL push_registration_list('[\"ntfytestb\"]',0,500)"

echo 'notification-v2 schema tests: PASS'
