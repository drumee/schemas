DELIMITER $

-- =========================================================
-- 
-- =========================================================


DROP PROCEDURE IF EXISTS `mfs_import`$
CREATE PROCEDURE `mfs_import`(
  IN _nodes JSON,
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN

    DECLARE _idx INT(4) DEFAULT 0; 
    DECLARE _id              VARCHAR(16) CHARACTER SET ascii;                                                                            
    DECLARE _origin_id       VARCHAR(16) CHARACTER SET ascii;                                                                            
    DECLARE _owner_id        VARCHAR(16) CHARACTER SET ascii;                                                                          
    DECLARE _host_id         VARCHAR(16) CHARACTER SET ascii;                                                                         
    DECLARE _file_path       VARCHAR(1000);                                                                         
    DECLARE _user_filename   VARCHAR(128);                                                                       
    DECLARE _parent_id       VARCHAR(16) CHARACTER SET ascii;                                                                        
    DECLARE _parent_path     VARCHAR(1024);                                                                        
    DECLARE _extension       VARCHAR(100);                                                                       
    DECLARE _mimetype        VARCHAR(100);                                                                        
    DECLARE _category        VARCHAR(16);                                                                         
    DECLARE _isalink         TINYINT(2) ;                                                              
    DECLARE _filesize        BIGINT(20) ;                                                                
    DECLARE _geometry        VARCHAR(200);                                                                           
    DECLARE _publish_time    INT(11) ;                                                                    
    DECLARE _upload_time     INT(11) ;                                                                          
    DECLARE _last_download   INT(11) ;                                                                 
    DECLARE _download_count  MEDIUMINT(8) ;                                                              
    DECLARE _metadata        LONGTEXT  ;                                                                             
    DECLARE _caption         VARCHAR(1024);                                                                         
    DECLARE _status          VARCHAR(20);                                                                            
    DECLARE _rank            INT(11);  
    DECLARE _ts   INT(11) DEFAULT 0;
    
    SELECT UNIX_TIMESTAMP() INTO _ts;

    WHILE _idx < JSON_LENGTH(_nodes) DO 
      SELECT get_json_array(_nodes, _idx) INTO @_node;
      SELECT get_json_object(@_node, "id") INTO _id;
      SELECT get_json_object(@_node, "parent_id") INTO _parent_id;
      SELECT get_json_object(@_node, "file_path") INTO _file_path;
      SELECT get_json_object(@_node, "parent_path") INTO _parent_path;
      SELECT get_json_object(@_node, "user_filename") INTO _user_filename;
      SELECT get_json_object(@_node, "extension") INTO _extension;
      SELECT get_json_object(@_node, "mimetype") INTO _mimetype;
      SELECT get_json_object(@_node, "category") INTO _category;
      SELECT get_json_object(@_node, "filesize") INTO _filesize;

      SELECT JSON_OBJECT('_seen_', JSON_OBJECT(_uid, UNIX_TIMESTAMP()))  INTO _metadata WHERE _category != 'folder' ;

      INSERT INTO `media` (
          id, 
          origin_id, 
          owner_id,
          file_path, 
          user_filename, 
          parent_id, 
          parent_path,
          extension, 
          mimetype, 
          category,
          isalink,
          filesize, 
          `geometry`, 
          publish_time, 
          upload_time, 
          `status`,
          rank,
          metadata
        )
      VALUES (
          _id, 
          _id, 
          _id,
          _file_path, 
          TRIM('/' FROM _user_filename),
          _parent_id, 
          _parent_path,
          _extension, 
          _mimetype, 
          _category, 
          0,
          IFNULL(_filesize, 4096),
          IFNULL( '0x0', '0x0'), 
          _ts, 
          _ts, 
          'active',
          1,
          _metadata
        );


      SELECT NULL INTO _id;
      SELECT NULL INTO _parent_id;
      SELECT NULL INTO _file_path;
      SELECT NULL INTO _parent_path;
      SELECT NULL INTO _user_filename;
      SELECT NULL INTO _extension;
      SELECT NULL INTO _mimetype;
      SELECT NULL INTO _category;


      SELECT _idx + 1 INTO _idx;

  END WHILE; 

END $

DELIMITER ;



