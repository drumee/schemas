#!/usr/bin/env bash
set -euo pipefail

db_name=${1:?usage: mobile-push-member-page.sh <disposable-db>}
case "$db_name" in
  notification_hub_test_*) ;;
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

sql "CREATE TABLE permission (
  entity_id VARCHAR(16) NOT NULL,
  resource_id VARCHAR(16) NOT NULL,
  permission INT UNSIGNED NOT NULL,
  expiry_time BIGINT UNSIGNED DEFAULT 0,
  PRIMARY KEY (entity_id, resource_id)
)"
mariadb "$db_name" \
  < "$(dirname "$0")/../hub/procedures/members/hub_members_for_mobile_push.sql"

insert_values=''
for index in $(seq 1 120); do
  insert_values+="('member-$(printf '%03d' "$index")','*',7,0),"
done
sql "INSERT INTO permission VALUES ${insert_values%,}"

expect first-page-count 45 \
  "SELECT COUNT(*) FROM (SELECT entity_id FROM permission WHERE resource_id='*' ORDER BY entity_id LIMIT 0,45) page"
first_page_end=$(sql "CALL hub_members_for_mobile_push(1,45)" | tail -n 1 | cut -f1)
if [[ "$first_page_end" != 'member-045' ]]; then
  echo "FAIL procedure-first-page-end: expected 'member-045', got '$first_page_end'" >&2
  exit 1
fi

second_page_start=$(sql "CALL hub_members_for_mobile_push(2,45)" | head -n 1 | cut -f1)
if [[ "$second_page_start" != 'member-046' ]]; then
  echo "FAIL procedure-second-page-start: expected 'member-046', got '$second_page_start'" >&2
  exit 1
fi

page_three_count=$(sql "CALL hub_members_for_mobile_push(3,45)" | wc -l | tr -d ' ')
if [[ "$page_three_count" != 30 ]]; then
  echo "FAIL third-page-count: expected '30', got '$page_three_count'" >&2
  exit 1
fi

echo 'mobile push hub member paging tests: PASS'
