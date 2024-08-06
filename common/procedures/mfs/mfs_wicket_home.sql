DELIMITER $



-- =========================================================
-- Get user's share box home (top) directory
-- =========================================================

DROP PROCEDURE IF EXISTS `mfs_wicket_home`$
CREATE PROCEDURE `mfs_wicket_home`(
  IN _uid VARCHAR(16)
)
BEGIN
  DECLARE _wicket_db_name VARCHAR(255);
  DECLARE _wicket_id VARCHAR(16);

    -- SELECT e.id  FROM yp.entity e INNER JOIN yp.hub h ON e.id = h.id  
    -- WHERE   e.area = 'dmz' AND e.type='hub' AND h.owner_id = _uid INTO _wicket_id ;

    SELECT h.id FROM 
      yp.hub h INNER JOIN yp.entity e on e.id=h.id
    WHERE h.owner_id=_uid AND `serial`=0
    INTO _wicket_id;

  -- SELECT e.id FROM yp.entity e 
  --   INNER JOIN hub sb ON e.id=sb.owner_id 
  --   WHERE e.owner_id=_uid AND area='restricted' INTO _sbx_id ;

    SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db_name;
    SET @st = CONCAT('CALL ', _wicket_db_name ,'.mfs_home()');
    PREPARE stamt FROM @st;
    EXECUTE stamt;
    DEALLOCATE PREPARE stamt;
END $


DELIMITER ;