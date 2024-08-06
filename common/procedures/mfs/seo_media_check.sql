


DELIMITER $



DROP PROCEDURE IF EXISTS `seo_media_check`$
CREATE PROCEDURE `seo_media_check`()
BEGIN
  DECLARE _hub_id VARCHAR(16) CHARACTER SET ascii ;
  DECLARE _home_dir VARCHAR(512);

  SELECT id ,home_dir INTO _hub_id,_home_dir from yp.entity  WHERE db_name = DATABASE();



  INSERT INTO yp.seo_factory_check (hub_id,nid,mfs_root,db_name,file_path,extension,mimetype,category)
  SELECT _hub_id, m.id,concat(_home_dir, "/__storage__/") , DATABASE(),m.file_path ,m.extension,m.mimetype,m.category 
  FROM media m
  LEFT JOIN  seo_object so on so.nid= m.id
  LEFT JOIN  yp.seo_factory_check f ON f.hub_id =_hub_id AND m.id = f.nid
  WHERE m.category NOT IN ('hub','folder','root')
  AND so.nid IS NULL AND f.nid IS NULL;
  -- ON DUPLICATE KEY UPDATE isprocessed=isprocessed;
END$

DELIMITER ;




