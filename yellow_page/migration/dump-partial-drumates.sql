DELIMITER $
DROP PROCEDURE IF EXISTS `migrate_drumate`$
DROP PROCEDURE IF EXISTS `migrate_drumates`$
CREATE PROCEDURE `migrate_drumates`(
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _ident VARCHAR(106);
  DECLARE _home_dir  text;
  DECLARE _sys_id   int(11) unsigned;
  DECLARE _finished       INTEGER DEFAULT 0;

  select e.id, e.sys_id, home_dir, db_name, ident, fingerprint, profile 
  from entity e join drumate using(id)    
  where ident in(
    'v',
    'brunatto',
    'theophane',
    'christelle',
    'philippe',
    'cecile'
  );
END$
DELIMITER ;