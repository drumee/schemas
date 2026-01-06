DELIMITER $

DROP FUNCTION IF EXISTS `get_quota`$
CREATE FUNCTION `get_quota`(
  _id VARCHAR(16)
)
RETURNS JSON DETERMINISTIC
BEGIN 
  DECLARE _res JSON;
  DECLARE _count INTEGER DEFAULT 0;
  DECLARE _domain_id INTEGER DEFAULT 0;

  SELECT count(*) FROM drumate WHERE domain_id > 1 AND domain_id 
    IN(SELECT domain_id FROM drumate WHERE id=_id) INTO _count;
  
  SELECT domain_id FROM drumate WHERE id=_id INTO _domain_id;
  IF _domain_id = 1 THEN 
    SELECT JSON_OBJECT(
    'id', q.id,
    'plan', JSON_VALUE(q.quota, "$.plan"),
    'billing_cycle', JSON_VALUE(q.quota, "$.billing_cycle"),
    'organization', JSON_VALUE(q.quota, "$.organization"),
    'seat', JSON_VALUE(q.quota, "$.seat"),
    'available_seat', JSON_VALUE(q.quota, "$.seat"),
    'total_seat', JSON_VALUE(q.quota, "$.seat"),
    'used_seat', JSON_VALUE(q.quota, "$.seat"),
    'tag', JSON_VALUE(q.quota, "$.tag"),
    'storage', JSON_VALUE(q.quota, "$.disk")
    )
    FROM quota q
      WHERE payer_id= 'ffffffffffffffff' AND q.domain_id=1 INTO _res;
  ELSE    
    SELECT JSON_OBJECT(
      'id', q.id,
      'plan', COALESCE(JSON_VALUE(dr.profile, "$.plan"), q.plan),
      'billing_cycle', COALESCE(JSON_VALUE(dr.quota, "$.billing_cycle"), JSON_VALUE(q.quota, "$.billing_cycle")),
      'organization', COALESCE(JSON_VALUE(dr.quota, "$.organization"), JSON_VALUE(q.quota, "$.organization")),
      'seat', (COALESCE(JSON_VALUE(dr.quota, "$.total_seat"), JSON_VALUE(q.quota, "$.seat"), 1) - _count),
      'available_seat', (COALESCE(JSON_VALUE(dr.quota, "$.total_seat"), JSON_VALUE(q.quota, "$.seat"), 1) - _count),
      'total_seat', COALESCE(JSON_VALUE(dr.quota, "$.total_seat"), JSON_VALUE(q.quota, "$.seat"), 1),
      'used_seat', _count,
      'storage', COALESCE(JSON_VALUE(dr.quota, "$.disk"), JSON_VALUE(q.quota, "$.disk"))
      )

    FROM drumate dr 
      INNER JOIN quota q USING(domain_id) WHERE dr.id = _id GROUP BY(dr.id) INTO _res;
  END IF;

  RETURN _res;
END$
DELIMITER ;
