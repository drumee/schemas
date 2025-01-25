 DELIMITER $
-- ==============================================================
-- mfs_show_node_by
-- List files + directories under directory identified by node_id
-- ==============================================================


DROP PROCEDURE IF EXISTS `readlog_update`$
CREATE PROCEDURE `readlog_update`(
  IN _uid VARCHAR(16) CHARACTER SET ascii,
  IN _lastread INT(11),
  IN _single_hub BOOLEAN
)
BEGIN

  DROP TABLE IF EXISTS `_myhubs`;
  CREATE TEMPORARY TABLE `_myhubs` (
    `id` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
    `sys_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
    `db_name` VARCHAR(120) CHARACTER SET ascii NOT NULL,  
    `home_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
    `owner_id` VARCHAR(16) CHARACTER SET ascii NOT NULL,
    `hubname` VARCHAR(256),
    `area` VARCHAR(16) CHARACTER SET ascii NOT NULL,  
    `accessibility` VARCHAR(32) CHARACTER SET ascii NOT NULL,  
    `is_checked` BOOLEAN DEFAULT 0,
    UNIQUE KEY `id` (`id`)
  );

  IF _single_hub THEN
    INSERT INTO _myhubs SELECT 
      e.id, 
      0, 
      e.db_name, 
      e.home_id, 
      h.owner_id, 
      h.hubname, 
      e.area,
      e.accessibility,
      0
      FROM yp.entity e 
      INNER JOIN yp.hub h ON e.id=h.id 
    WHERE e.db_name=DATABASE();
  ELSE
    INSERT INTO _myhubs SELECT 
      m.id, 
      m.sys_id, 
      e.db_name, 
      e.home_id, 
      h.owner_id, 
      h.hubname, 
      e.area,
      e.accessibility,
      0
      FROM media m 
      INNER JOIN yp.entity e ON m.id=e.id 
      INNER JOIN yp.hub h ON m.id=h.id 
    WHERE m.category='hub' AND m.status <> 'hidden' ;

    INSERT INTO _myhubs SELECT 
      e.id, 
      0,
      e.db_name, 
      e.home_id, 
      _uid, 
      d.username, 
      'personal',
      'personal',
      1
    FROM yp.entity e 
      INNER JOIN yp.drumate d ON e.id=d.id 
    WHERE d.id = _uid;

  END IF;


  INSERT IGNORE INTO readlog SELECT 
    _uid,
    c.ref_hubid, 
    c.ref_pid, 
    c.ref_nid, 
    c.ref_ctime, 
    IF(c.uid=_uid, 0, 1)
    FROM yp.mfs_changelog c 
      INNER JOIN _myhubs h ON h.id=c.ref_hubid
      WHERE c.event IN("media.new", "media.copy") AND c.ref_ctime >= _lastread;

END $

DELIMITER ;

