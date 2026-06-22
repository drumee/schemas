DELIMITER $
DROP PROCEDURE IF EXISTS `payment_apply_entitlement`$
CREATE PROCEDURE `payment_apply_entitlement`(
  IN _entity_id VARCHAR(16) CHARACTER SET ascii,   -- payer (user id); P1 = individual
  IN _plan_code VARCHAR(30) CHARACTER SET ascii,
  IN _period_end INT(11) UNSIGNED
)
BEGIN
  DECLARE _domain_id INT(11) UNSIGNED;
  DECLARE _plan_quota JSON;
  -- 1) domain for this payer (mirror get_quota cascade key)
  SELECT domain_id FROM yp.drumate WHERE id = _entity_id LIMIT 1 INTO _domain_id;
  SET _domain_id = IFNULL(_domain_id, 1);
  -- 2) quota JSON the plan grants (from the rebuilt catalog)
  SELECT quota FROM yp.plan WHERE plan_code = _plan_code AND entity_type = 'user' AND active = 1 LIMIT 1 INTO _plan_quota;
  SET _plan_quota = IFNULL(_plan_quota, JSON_OBJECT('plan', _plan_code, 'disk', 20000000000));
  -- 3) canonical upsert (UNIQUE key (domain_id,payer_id))
  INSERT INTO yp.quota (domain_id, payer_id, plan, quota, source, period_end, ctime, mtime)
  VALUES (_domain_id, _entity_id, _plan_code, JSON_SET(_plan_quota, '$.plan', _plan_code), 'stripe', _period_end, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE
    plan = _plan_code, quota = VALUES(quota), source = 'stripe', period_end = _period_end, mtime = UNIX_TIMESTAMP();
  -- 4) return applied row for reducer/WS payload
  SELECT _entity_id AS entity_id, _domain_id AS domain_id, _plan_code AS plan,
         _period_end AS period_end, JSON_VALUE(_plan_quota, '$.disk') AS disk;
END $
DELIMITER ;
