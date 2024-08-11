DELIMITER $
DROP PROCEDURE IF EXISTS `migrate`$
DROP PROCEDURE IF EXISTS `migrate_hubs`$
CREATE PROCEDURE `migrate_hubs`(
)
BEGIN
  DECLARE _id VARCHAR(16);
  DECLARE _db_name VARCHAR(50);
  DECLARE _ident VARCHAR(106);
  DECLARE _home_dir  text;
  DECLARE _sys_id   int(11) unsigned;
  DECLARE _finished       INTEGER DEFAULT 0;
    
  DECLARE dbcursor CURSOR FOR 
    select id, sys_id, home_dir, db_name, ident from entity 
    where ident 
    in(
      'christelle', 
      'c', 
      'theophane', 
      'v', 
      'brunatto', 
      'emmanuelle', 
      'philippe', 
      'cecile', 
      'nisel', 
      'n', 
      'theo'
    );
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1;

  DROP TABLE IF EXISTS __migration;
  CREATE TEMPORARY TABLE __migration  AS 
    select e.id, e.sys_id, e.status, e.area, e.db_name, e.home_dir, h.owner_id, e.ident, user_filename
    from yp.hub h inner join (yp.entity e, B_nobody.media m) on e.id=h.id and m.id=e.id;
  alter table __migration  add unique key db_name (db_name, home_dir);

  OPEN dbcursor;

  STARTLOOP: LOOP
    FETCH dbcursor INTO _id, _sys_id, _home_dir, _db_name, _ident ;
    IF _finished = 1 THEN 
      LEAVE STARTLOOP;
    END IF;    
    SET @s = CONCAT("
      REPLACE INTO __migration select e.id, e.sys_id, e.status, e.area, e.db_name, e.home_dir, h.owner_id, e.ident, user_filename 
      from yp.hub h inner join (yp.entity e, ",
       _db_name, 
       ".media m) on e.id=h.id and m.id=e.id");
    
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  END LOOP STARTLOOP;   
  CLOSE dbcursor;
  SELECT * FROM __migration;
END$
DELIMITER ;