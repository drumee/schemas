DELIMITER $

-- =========================================================
-- org_membership_get
-- =========================================================
-- The person's standing in an organisation that is NOT their primary one:
-- one row {privilege} from org_membership, or no row. Used per request by
-- service/lib/active-org.js only when the address being visited belongs to
-- an organisation other than the person's own.
DROP PROCEDURE IF EXISTS `org_membership_get`$
CREATE PROCEDURE `org_membership_get`(
  IN _uid       VARCHAR(16),
  IN _domain_id INT UNSIGNED
)
BEGIN
  SELECT m.uid, m.domain_id, m.privilege
    FROM org_membership m
   WHERE m.uid = _uid AND m.domain_id = _domain_id
   LIMIT 1;
END$

DELIMITER ;
