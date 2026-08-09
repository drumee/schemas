DELIMITER $
DROP FUNCTION IF EXISTS `disk_used`$
DROP FUNCTION IF EXISTS `disk_free`$
CREATE FUNCTION `disk_free`(
  _entity_id  VARCHAR(16) CHARACTER SET ascii
) RETURNS double
DETERMINISTIC
BEGIN
  DECLARE _uid VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _owner_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _drumate_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _quota json ;
  DECLARE _domain_id INT(11) UNSIGNED;

  DECLARE _u_desk_disk  double  default 0.0 ;
  DECLARE _u_hub_disk  double  default 0.0 ;


  DECLARE _q_desk_disk  double  default 0.0 ;
  DECLARE _q_hub_disk  double  default 0.0 ;
  DECLARE _q_disk  double  default 0.0 ;


  DECLARE _l_disk  double  default 0.0 ;

  SELECT id, owner_id  FROM yp.hub WHERE id = _entity_id  INTO _hub_id , _owner_id; 
  SELECT id FROM yp.drumate WHERE id = _entity_id  AND  _owner_id IS NULL  INTO _owner_id; 

  -- Entitlement source = yp.quota (canonical), legacy profile.quota fallback (tier 3).
  SELECT domain_id FROM yp.drumate WHERE id = _owner_id INTO _domain_id;
  -- An EXPIRED reward is skipped so it falls through to the tiers below. The
  -- claim-reward campaign grants 5 years of unlimited storage as a
  -- source='reward' row, and period_end is enforced at READ time rather than by
  -- a sweeper.
  --
  -- The guard matters MORE here than in disk_limit: this function is
  -- personal-FIRST (see the tier order below, which differs from disk_limit,
  -- my_disk_limit and get_quota -- a pre-existing inconsistency). Without it an
  -- expired reward row would outrank even the domain entitlement.
  --
  -- Scoped to source='reward'; NULL period_end reads as "no expiry" alongside 0.
  SELECT quota FROM yp.quota
   WHERE payer_id = _owner_id
     AND (IFNULL(source, 'free') <> 'reward'
          OR IFNULL(period_end, 0) = 0
          OR period_end > UNIX_TIMESTAMP())
   LIMIT 1 INTO _quota;
  IF _quota IS NULL AND _domain_id > 1 THEN
    SELECT quota FROM yp.quota WHERE domain_id = _domain_id LIMIT 1 INTO _quota;
  END IF;
  IF _quota IS NULL THEN
    SELECT quota FROM yp.drumate WHERE id = _owner_id INTO _quota;
  END IF;
  IF _quota IS NULL THEN
    SELECT quota FROM yp.quota WHERE payer_id = 'ffffffffffffffff' AND domain_id = 1 LIMIT 1 INTO _quota;
  END IF;

    SELECT JSON_VALUE(_quota, "$.disk") INTO _q_disk;
    SELECT JSON_VALUE(_quota, "$.desk_disk") INTO _q_desk_disk;
    SELECT JSON_VALUE(_quota, "$.hub_disk") INTO _q_hub_disk;
    SELECT IFNULL(_q_desk_disk,_q_disk) INTO _q_desk_disk;
    SELECT IFNULL(_q_hub_disk,_q_disk) INTO _q_hub_disk;


  -- USAGE. An organisation shares ONE allowance (Team sells 100 GB for the
  -- team, not 100 GB each) so an org domain is measured across every member;
  -- a personal account is measured alone. Domain 1 is the shared free-users
  -- domain -- 2991 accounts on prod -- and must never be summed that way.
  --
  -- This used to branch on _org_id and sum through `map_role`, which is the
  -- CUSTOM-ROLE assignment table (adminpannel/role_map writes it) and holds
  -- no rows until somebody assigns a custom role: 0 on prod, 1 on stage. Every
  -- org member therefore measured as using NOTHING and was handed the entire
  -- quota. Org membership lives in `privilege`, keyed by domain_id.
  --
  -- `IN (...)` rather than a join so a member holding more than one privilege
  -- row cannot count their bytes twice.
  IF _domain_id > 1 THEN

      SELECT SUM(du.size)
        FROM yp.disk_usage du
        INNER JOIN yp.hub h ON du.hub_id = h.id
       WHERE h.owner_id IN (SELECT p.uid FROM yp.privilege p WHERE p.domain_id = _domain_id)
        INTO _u_hub_disk;

      SELECT SUM(du.size)
        FROM yp.disk_usage du
        INNER JOIN yp.drumate d ON du.hub_id = d.id
       WHERE d.id IN (SELECT p.uid FROM yp.privilege p WHERE p.domain_id = _domain_id)
        INTO _u_desk_disk;

  ELSE

      SELECT SUM(du.size)
        FROM yp.disk_usage du
        INNER JOIN yp.hub h ON du.hub_id = h.id
       WHERE h.owner_id = _owner_id
        INTO _u_hub_disk;

      SELECT SUM(du.size)
        FROM yp.disk_usage du
        INNER JOIN yp.drumate d ON du.hub_id = d.id
       WHERE d.id = _owner_id
        INTO _u_desk_disk;

  END IF ;

  SELECT IFNULL(_u_hub_disk , 0)  INTO _u_hub_disk;
  SELECT IFNULL(_u_desk_disk , 0)  INTO _u_desk_disk;

  -- The total term is the same either way; the context only decides which
  -- sub-cap also applies.
  IF _hub_id IS NULL THEN
      SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk , _q_desk_disk - _u_desk_disk ) INTO _l_disk;
  ELSE
      SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk , _q_hub_disk  - _u_hub_disk  ) INTO _l_disk;
  END IF ;

  RETURN _l_disk;

END$



DELIMITER ;


