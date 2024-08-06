DELIMITER $




DROP PROCEDURE IF EXISTS `seo_media_get`$
CREATE PROCEDURE `seo_media_get`()
BEGIN

  SELECT  sys_id,hub_id , nid ,db_name ,extension, mimetype,category,mfs_root,file_path 
  FROM  seo_factory_check 
  WHERE isprocessed = 0  ;

  -- AND   hub_id not in ('21cf9a3f21cf9a5a' ,'3fa1f5883fa1f58e') AND nid not in ( '01306add01306af0' , '87523f1587523f2d', '876a0e16876a0e23', '87885de687885df5','1d196d231d196d2f') ;

END$


DROP PROCEDURE IF EXISTS `seo_media_remove`$
CREATE PROCEDURE `seo_media_remove`(
  IN _hub_id       VARCHAR(16) CHARACTER SET ascii,
  IN _nid        VARCHAR(16) CHARACTER SET ascii

)
BEGIN

  DELETE 
  FROM seo_factory_check
  WHERE hub_id =_hub_id AND 
        nid = _nid;
END$



DROP PROCEDURE IF EXISTS `seo_media_update`$
CREATE PROCEDURE `seo_media_update`(
  IN _hub_id       VARCHAR(16) CHARACTER SET ascii,
  IN _nid        VARCHAR(16) CHARACTER SET ascii,
  IN _status    INT

)
BEGIN

  UPDATE  seo_factory_check
  SET isprocessed = -_status
  WHERE hub_id =_hub_id AND 
        nid = _nid;
END$


-- =========================================================
-- entity_update_settings
-- =========================================================

DROP PROCEDURE IF EXISTS `seo_factory`$
CREATE PROCEDURE `seo_factory`()
BEGIN
  DECLARE _tempid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(255) CHARACTER SET ascii;
 
  DROP TABLE IF EXISTS _seo_check; 
  CREATE  TEMPORARY TABLE _seo_check (
    id varchar(16)  CHARACTER SET ascii DEFAULT NULL,
    db_name VARCHAR(40),
    is_checked boolean default 0 
    );
 
  TRUNCATE  table  seo_factory_check;


  INSERT INTO _seo_check
  SELECT e.id,db_name,0 
  FROM yp.entity e
  LEFT JOIN  yp.hub h on h.id = e.id
  LEFT JOIN yp.drumate d on d.id = e.id
  WHERE  (h.id IS NOT NULL OR e.id IS NOT NULL)
  AND e.type in ('hub','drumate') AND e.id <> 'ffffffffffffffff' ;
 
  SELECT  id ,db_name INTO _tempid ,_db_name FROM _seo_check WHERE is_checked = 0 LIMIT  1  ; 
  WHILE _tempid IS NOT NULL DO
    -- SELECT _tempid;


      SET @st = CONCAT("CALL ", _db_name, ".seo_media_check()");
      PREPARE stmt2 FROM @st;
      EXECUTE stmt2 ;           
      DEALLOCATE PREPARE stmt2;



    UPDATE _seo_check SET is_checked = 1 WHERE id =_tempid;
    SELECT NULL INTO _tempid;
    SELECT  id ,db_name INTO _tempid ,_db_name FROM _seo_check WHERE is_checked = 0 LIMIT  1  ; 
  END WHILE; 

 
END $

DELIMITER ;



