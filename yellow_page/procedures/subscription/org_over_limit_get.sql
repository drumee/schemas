DELIMITER $

-- =========================================================
-- org_over_limit_get
-- Scalar read of the org's over-limit state for one domain —
-- the shape the REST read-only clamp and the invite guards
-- consume on every mutating request (so: cheap, indexed by the
-- organisation.domain_id UNIQUE key, no JSON blobs returned).
-- Empty result = personal domain / no org = never locked.
-- =========================================================
DROP PROCEDURE IF EXISTS `org_over_limit_get`$
CREATE PROCEDURE `org_over_limit_get`(
  IN _domain_id INT(11) UNSIGNED
)
BEGIN
  SELECT
    o.id AS org_id,
    o.owner_id,
    o.domain_id,
    JSON_UNQUOTE(JSON_VALUE(o.metadata, '$.over_limit.state')) AS state,
    CAST(IFNULL(JSON_VALUE(o.metadata, '$.over_limit.flags.storage'), 0) AS UNSIGNED) AS storage_over,
    CAST(IFNULL(JSON_VALUE(o.metadata, '$.over_limit.flags.seats'), 0) AS UNSIGNED) AS seats_over,
    CAST(IFNULL(JSON_VALUE(o.metadata, '$.over_limit.grace_deadline'), 0) AS UNSIGNED) AS grace_deadline
  FROM organisation o
  WHERE o.domain_id = _domain_id;
END $

DELIMITER ;
