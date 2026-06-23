DELIMITER $
DROP PROCEDURE IF EXISTS `payment_apply_entitlement`$
CREATE PROCEDURE `payment_apply_entitlement`(
  IN _entity_id VARCHAR(16) CHARACTER SET ascii,   -- user id (individual) OR organisation id (org)
  IN _plan_code VARCHAR(30) CHARACTER SET ascii,
  IN _period_end INT(11) UNSIGNED,
  IN _entity_type VARCHAR(8) CHARACTER SET ascii,  -- 'user' | 'org'  (P3)
  IN _seats INT(11) UNSIGNED                        -- org per-seat quantity (P3)
)
BEGIN
  DECLARE _domain_id INT(11) UNSIGNED;
  DECLARE _payer_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _plan_quota JSON;
  DECLARE _per_seat_disk BIGINT UNSIGNED;
  SET _entity_type = IFNULL(NULLIF(_entity_type, ''), 'user');
  SET _seats = IFNULL(_seats, 1);

  IF _entity_type = 'org' THEN
    -- Org: _entity_id = organisation id; the entitlement is keyed by the org's
    -- domain so get_quota / disk_limit tier-2 (WHERE domain_id) cascades it to
    -- every member. Per-seat: total disk = seats * the plan's per-seat disk.
    SELECT domain_id FROM yp.organisation WHERE id = _entity_id LIMIT 1 INTO _domain_id;
    SET _domain_id = IFNULL(_domain_id, 1);
    SET _payer_id = _entity_id;  -- org row, distinct from member payer rows
    SELECT quota FROM yp.plan WHERE plan_code = _plan_code AND entity_type = 'org' AND active = 1 LIMIT 1 INTO _plan_quota;
    SET _plan_quota = IFNULL(_plan_quota, JSON_OBJECT('plan', _plan_code, 'disk', 50000000000));
    SET _per_seat_disk = IFNULL(JSON_VALUE(_plan_quota, '$.disk'), 50000000000);
    SET _plan_quota = JSON_SET(_plan_quota, '$.plan', _plan_code, '$.seat', _seats,
                               '$.organization', 1, '$.disk', _per_seat_disk * _seats);
  ELSE
    -- Individual (P1): payer-keyed row.
    SELECT domain_id FROM yp.drumate WHERE id = _entity_id LIMIT 1 INTO _domain_id;
    SET _domain_id = IFNULL(_domain_id, 1);
    SET _payer_id = _entity_id;
    SELECT quota FROM yp.plan WHERE plan_code = _plan_code AND entity_type = 'user' AND active = 1 LIMIT 1 INTO _plan_quota;
    SET _plan_quota = IFNULL(_plan_quota, JSON_OBJECT('plan', _plan_code, 'disk', 20000000000));
    SET _plan_quota = JSON_SET(_plan_quota, '$.plan', _plan_code);
  END IF;

  INSERT INTO yp.quota (domain_id, payer_id, plan, quota, source, period_end, ctime, mtime)
  VALUES (_domain_id, _payer_id, _plan_code, _plan_quota, 'stripe', _period_end, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE
    plan = _plan_code, quota = VALUES(quota), source = 'stripe', period_end = _period_end, mtime = UNIX_TIMESTAMP();

  SELECT _entity_id AS entity_id, _domain_id AS domain_id, _entity_type AS entity_type,
         _plan_code AS plan, _seats AS seats, _period_end AS period_end,
         JSON_VALUE(_plan_quota, '$.disk') AS disk;
END $
DELIMITER ;
