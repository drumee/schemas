DELIMITER $

DROP FUNCTION IF EXISTS `get_quota`$
CREATE FUNCTION `get_quota`(
  _id VARCHAR(16)
)
RETURNS JSON DETERMINISTIC
BEGIN 
  DECLARE _res JSON;
  DECLARE _count INTEGER DEFAULT 0;

  SELECT count(*) FROM drumate WHERE domain_id>1 AND domain_id 
    IN(SELECT domain_id FROM drumate WHERE id=_id) INTO _count;

  -- SELECT IFNULL(JSON_VALUE(profile, "$.category"), "default"), IFNULL(quota, "{}"), domain_id
  --   FROM drumate WHERE id=_args OR email=_args 
  --    INTO _category, _quota, _domain_id;
  
  SELECT JSON_OBJECT(
    'plan', COALESCE(JSON_VALUE(dr.profile, "$.plan"), q.plan),
    'billing_cycle', JSON_VALUE(dr.profile, "$.billing_cycle"),
    'organization', COALESCE(JSON_VALUE(dr.quota, "$.organization"), JSON_VALUE(q.quota, "$.organization")),
    'seat', (COALESCE(JSON_VALUE(dr.quota, "$.seat"), JSON_VALUE(q.quota, "$.seat")) - _count),
    'available_seat', (COALESCE(JSON_VALUE(dr.quota, "$.seat"), JSON_VALUE(q.quota, "$.seat")) - _count),
    'total_seat', (COALESCE(JSON_VALUE(dr.quota, "$.seat"), JSON_VALUE(q.quota, "$.seat"))),
    'used_seat', (COALESCE(JSON_VALUE(dr.quota, "$.seat"), JSON_VALUE(q.quota, "$.seat"))),
    'storage', COALESCE(JSON_VALUE(dr.quota, "$.disk"), JSON_VALUE(q.quota, "$.disk"))
    )

  FROM drumate dr INNER JOIN quota q USING(domain_id) WHERE dr.id=_id GROUP BY(dr.id) INTO _res;
  RETURN _res;
END$
DELIMITER ;
