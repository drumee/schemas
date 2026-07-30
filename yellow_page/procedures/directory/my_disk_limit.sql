DELIMITER $

DROP PROCEDURE IF EXISTS `my_disk_limit`$
CREATE PROCEDURE `my_disk_limit`(
  _uid  VARCHAR(16) CHARACTER SET ascii
)
BEGIN

  DECLARE _desk_disk  double  default 0.0 ;
  DECLARE _private_disk  double  default 0.0 ;
  DECLARE _chat_disk  double  default 0.0 ;
  DECLARE _share_disk  double  default 0.0 ;

  DECLARE _quota json ;
  DECLARE _domain_id INT(11) UNSIGNED;
  DECLARE _q_desk_disk  double  default 0.0 ;
  DECLARE _q_hub_disk  double  default 0.0 ;
  DECLARE _q_disk  double  default 0.0 ;
  DECLARE _watermark VARCHAR(16)  CHARACTER SET ascii default "0";


  -- Entitlement source = yp.quota (canonical), legacy profile.quota fallback (tier 3).
  SELECT domain_id FROM yp.drumate WHERE id = _uid INTO _domain_id;
  -- Tenant-first entitlement: when the user lives in an org domain, the
  -- ORGANISATION's quota row (payer_id = organisation.id) outranks any
  -- personal payer row — a pro→team upgrader owns both for a while and
  -- must see/enforce the TEAM plan, not their stale personal one. The
  -- org row is matched via organisation (deterministic: a domain can now
  -- hold several rows under UNIQUE(domain_id, payer_id)).
  IF _domain_id > 1 THEN
    SELECT q.quota FROM yp.quota q
      INNER JOIN yp.organisation o ON o.domain_id = q.domain_id AND o.id = q.payer_id
     WHERE q.domain_id = _domain_id LIMIT 1 INTO _quota;
  END IF;
  -- An EXPIRED reward is skipped, dropping through to the tiers below. The
  -- claim-reward campaign grants 5 years of unlimited storage as a
  -- source='reward' row and period_end is enforced at READ time, so the term
  -- ends without a sweeper. Scoped to source='reward' -- Stripe rows carry
  -- period_end informationally and cancellation DELETEs them. NULL reads as
  -- "no expiry" alongside 0.
  IF _quota IS NULL THEN
    SELECT quota FROM yp.quota
     WHERE payer_id = _uid
       AND (IFNULL(source, 'free') <> 'reward'
            OR IFNULL(period_end, 0) = 0
            OR period_end > UNIX_TIMESTAMP())
     LIMIT 1 INTO _quota;
  END IF;
  IF _quota IS NULL THEN
    SELECT quota FROM yp.drumate WHERE id = _uid INTO _quota;
  END IF;
  IF _quota IS NULL THEN
    SELECT quota FROM yp.quota WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1 LIMIT 1 INTO _quota;
  END IF;
  SELECT JSON_VALUE(_quota, "$.watermark") INTO _watermark;
  SELECT JSON_VALUE(_quota, "$.disk") INTO _q_disk;
  SELECT JSON_VALUE(_quota, "$.desk_disk") INTO _q_desk_disk;
  SELECT JSON_VALUE(_quota, "$.hub_disk") INTO _q_hub_disk;
  SELECT IFNULL(_q_desk_disk,_q_disk) INTO _q_desk_disk;
  SELECT IFNULL(_q_hub_disk,_q_disk) INTO _q_hub_disk;



  SELECT 
    SUM(CASE WHEN e.area = 'dmz' THEN du.size ELSE 0 END ) chat,
    SUM(CASE WHEN e.area = 'private' THEN du.size ELSE 0 END ) private,
    SUM(CASE WHEN e.area = 'share' THEN du.size ELSE 0 END) share
  FROM 
    yp.disk_usage du
    INNER JOIN yp.hub h ON du.hub_id = h.id
    INNER JOIN entity e ON e.id = du.hub_id
    WHERE h.owner_id=_uid 
    INTO _chat_disk, _private_disk, _share_disk;

  SELECT 
    SUM(du.size) 
  FROM 
    yp.disk_usage du
    INNER JOIN yp.drumate d ON du.hub_id = d.id
    WHERE d.id=_uid
    INTO _desk_disk;

  SELECT _q_disk quota_disk,
    _chat_disk chat,
    _private_disk private,
    _share_disk share,
    _desk_disk desk,
    -- Unlimited storage (claim-reward entitlement). quota_disk above still
    -- carries the BIGINT sentinel so any arithmetic stays safe; this is the
    -- flag a caller renders "Unlimited" from instead of showing 9.2 EB.
    IF(JSON_VALUE(_quota, '$.unlimited') IN ('true', '1'), 1, 0) unlimited,
    _watermark watermark
  ;


END$

DELIMITER ;


