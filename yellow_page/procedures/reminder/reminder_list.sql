DELIMITER $

DROP PROCEDURE IF EXISTS `reminder_list`$
CREATE PROCEDURE `reminder_list`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _db_name VARCHAR(160) DEFAULT NULL;
  DECLARE _nid VARCHAR(160) DEFAULT NULL;
  DECLARE _parent_id VARCHAR(160) DEFAULT NULL;
  DECLARE _hub_id VARCHAR(160) DEFAULT NULL;
  DECLARE _finished INTEGER DEFAULT 0;
  DECLARE dbcursor CURSOR FOR 
    SELECT db_name, nid, hub_id FROM reminder r INNER JOIN entity e ON hub_id=e.id WHERE `uid`=_uid;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
  DROP TABLE IF EXISTS __tmp_media;
  CREATE TEMPORARY TABLE __tmp_media (
    `media_id` VARCHAR(16) DEFAULT NULL,
    `parent_id` VARCHAR(16) DEFAULT NULL,
    `filename` VARCHAR(1024) DEFAULT NULL,
    `hub_id` VARCHAR(16) DEFAULT NULL,
    PRIMARY KEY id(hub_id, media_id)
  );
  OPEN dbcursor;
    STARTLOOP: LOOP
      FETCH dbcursor INTO _db_name, _nid, _hub_id;
        IF _finished = 1 THEN 
          LEAVE STARTLOOP;
        END IF;  
        SET @s = CONCAT("REPLACE INTO __tmp_media SELECT id, parent_id, CONCAT(user_filename, '.', extension), ", 
          quote(_hub_id), " FROM ", _db_name, ".media WHERE id=", quote(_nid));
        -- SELECT @s;
        IF @s IS NOT NULL THEN 
          PREPARE stmt FROM @s;
          EXECUTE stmt;
          DEALLOCATE PREPARE stmt;
        END IF;
    END LOOP STARTLOOP;
  CLOSE dbcursor;
  SELECT r.*, t.parent_id pid, r.id reminder_id, t.filename FROM 
    reminder r INNER JOIN __tmp_media t ON t.hub_id=r.hub_id AND t.media_id=nid;
  -- DROP TABLE IF EXISTS __tmp_media;
END$

DELIMITER ;

-- #####################
