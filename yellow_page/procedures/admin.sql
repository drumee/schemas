DELIMITER $

-- =========================================================
--
-- ADMIN STUFFS
--
-- =========================================================


-- ***********************************************************************
-- MAINTENACE SECTION
-- ***********************************************************************


-- =======================================================================
-- For admin 
-- =======================================================================
DROP PROCEDURE IF EXISTS `list_procs`$
CREATE PROCEDURE `list_procs`(
  IN _dbname VARCHAR(32)
)
BEGIN

  SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = _dbname
  AND ROUTINE_TYPE = 'PROCEDURE';

END $

-- =========================================================
-- Gets frozen entities
-- =========================================================
DROP PROCEDURE IF EXISTS `get_frozen_entities`$
CREATE PROCEDURE `get_frozen_entities`()
BEGIN
  SELECT id, ident, fs_host, home_dir, db_name, type FROM entity WHERE status = 'frozen' AND UNIX_TIMESTAMP(TIMESTAMPADD(DAY,90, FROM_UNIXTIME(frozen_time))) < UNIX_TIMESTAMP();
END$

-- =========================================================
-- Clean frozen entities
-- =========================================================
DROP PROCEDURE IF EXISTS `clean_frozen_entities`$
CREATE PROCEDURE `clean_frozen_entities`()
BEGIN
  DECLARE _ts INT(11);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION, SQLWARNING
  BEGIN
    ROLLBACK;
    SELECT 1 AS error;
  END;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  CREATE TEMPORARY TABLE frozen_entity SELECT id, ident, fs_host, home_dir, db_name, type FROM entity WHERE status = 'frozen' AND UNIX_TIMESTAMP(TIMESTAMPADD(DAY,90, FROM_UNIXTIME(frozen_time))) < _ts;
  START TRANSACTION;
    DELETE FROM mailserver.users WHERE username in (SELECT ident FROM frozen_entity);
    DELETE FROM vhost WHERE id IN (SELECT id FROM frozen_entity);
    DELETE FROM drumate WHERE id IN (SELECT id FROM frozen_entity);
    DELETE FROM hub WHERE id IN (SELECT id FROM frozen_entity);
    DELETE FROM entity WHERE id IN (SELECT id FROM frozen_entity);
  COMMIT;
  SELECT 0 AS error, id, ident, fs_host, home_dir, db_name, type FROM frozen_entity;
END$

-- =========================================================
-- Clean frozen entities
-- =========================================================
DROP PROCEDURE IF EXISTS `__show`$
CREATE PROCEDURE `__show`(
  IN _key VARCHAR(512)
)
BEGIN
  DECLARE _type VARCHAR(20);
  SELECT type FROM entity  WHERE ident=_key OR id=_key OR vhost=_key INTO _type;

  IF _type = 'drumate' THEN 
    SELECT 
      e.id,
      sb.id AS sb_id,
      ident,
      vhost,
      db_name,
      (SELECT db_name FROM entity WHERE id=sb.owner_id) AS sb_db,
      domain,
      home_dir   
    FROM entity e LEFT JOIN share_box sb ON sb.owner_id=e.id 
    WHERE ident=_key OR e.id=_key OR vhost=_key;
  ELSE 
    SELECT
      id,
      ident,
      vhost,
      db_name,
      domain,
      home_dir   
    FROM entity WHERE ident=_key OR id=_key OR vhost=_key;
  END IF;
END$

DELIMITER ;

-- #####################
