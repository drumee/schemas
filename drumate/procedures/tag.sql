DELIMITER $

DROP PROCEDURE IF EXISTS `tag_add`$
CREATE PROCEDURE `tag_add`(
    _name VARCHAR(255),
    _parent_id VARCHAR(16)
)
BEGIN
    
    DECLARE _tag_id VARCHAR(16);
    DECLARE _tag_time int(11) unsigned;
    DECLARE _position int(11) unsigned;
    
    SELECT UNIX_TIMESTAMP() INTO _tag_time; 
    SELECT  yp.uniqueId() INTO _tag_id; 
    SELECT MAX(position) FROM tag INTO _position;

    SELECT IFNULL(_position,0) +1 INTO _position;

    IF _parent_id = '' THEN 
      SELECT NULL INTO _parent_id;
    END IF;  
    
    SELECT unique_tagname(_name,NULL) INTO _name;

    INSERT INTO tag(tag_id,parent_tag_id,name,ctime,position) 
    SELECT _tag_id,_parent_id,_name,_tag_time,_position;

    SELECT * FROM tag WHERE tag_id = _tag_id;

END$


DROP PROCEDURE IF EXISTS `entity_assign`$
CREATE PROCEDURE `entity_assign`(
    _tag_id VARCHAR(50),
    _entity_id VARCHAR(16),
    _category  VARCHAR(16)
   
)
BEGIN
   
    DECLARE _tag_time int(11) unsigned;
    SELECT UNIX_TIMESTAMP() INTO _tag_time; 
  
    INSERT INTO map_tag(tag_id,id, category,ctime) 
    SELECT _tag_id,_entity_id,_category,_tag_time ON DUPLICATE KEY UPDATE ctime =_tag_time , tag_id=_tag_id;

    SELECT * FROM map_tag WHERE tag_id = _tag_id;

END$



DROP PROCEDURE IF EXISTS `tag_remove`$
CREATE PROCEDURE `tag_remove`(
    _tag_id VARCHAR(50)   
)
BEGIN
    
    DECLARE _lvl INT(4);

        DROP TABLE IF EXISTS _tag;
        CREATE TEMPORARY TABLE _tag(
            `tag_id` varchar(16) NOT NULL,
            `is_checked` boolean default 0
        );
        INSERT INTO _tag (tag_id) SELECT _tag_id;
        WHILE (IFNULL((SELECT 1 FROM _tag  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO
            SELECT tag_id  FROM _tag WHERE is_checked = 0 LIMIT 1  INTO _tag_id;
            INSERT INTO _tag (tag_id) SELECT tag_id FROM tag WHERE  parent_tag_id = _tag_id;
            UPDATE _tag SET is_checked =  1 WHERE tag_id =_tag_id; 
            SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
        END WHILE; 

        DELETE FROM map_tag WHERE tag_id IN (SELECT tag_id FROM _tag);
        DELETE FROM tag WHERE tag_id IN (SELECT tag_id FROM _tag);

END$



DROP PROCEDURE IF EXISTS `tag_get`$
CREATE PROCEDURE `tag_get`(
    _key  VARCHAR(50),
    _chk_tag_id VARCHAR(50)
)

BEGIN
    DECLARE _tag_id VARCHAR(16);
    DECLARE _lvl INT(4);    
    DECLARE _is_any_child int(1) default 0;
    
        SELECT tag_id FROM tag WHERE tag_id = _key or name = _key INTO _tag_id;
        SELECT  1  FROM tag WHERE parent_tag_id =  _tag_id LIMIT 1 INTO _is_any_child;
        SELECT tag_id,parent_tag_id,_is_any_child as is_any_child,name,position FROM tag WHERE tag_id = _tag_id AND 
        tag_id <> IFNULL(_chk_tag_id,'xxxxxx');
 
END$


DROP PROCEDURE IF EXISTS `tag_get_next`$
CREATE PROCEDURE `tag_get_next`(
    IN _key  VARCHAR(50),
    IN _search VARCHAR(255), -- ,
    IN _order   VARCHAR(20),
    IN  _page INT(6)
)
BEGIN
  DECLARE _tag_id VARCHAR(16);
    
  DECLARE _range bigint;
  DECLARE _offset bigint;
    -- DECLARE _order   VARCHAR(20) default 'asc';

  CALL pageToLimits(_page, _offset, _range);

  SELECT 
    _page as `page`,
    tag_id,
    parent_tag_id,
    name,
    IFNULL((SELECT  1  FROM tag c WHERE c.parent_tag_id = p.tag_id LIMIT 1),0) is_any_child,
    position,
    IFNULL(( 
      SELECT 
        COUNT(1)
      FROM 
        channel ch 
      INNER JOIN  read_channel rc ON ch.entity_id= rc.entity_id 
      INNER JOIN  contact c ON c.entity = ch.entity_id
      INNER JOIN  map_tag mt ON  c.id = mt.id
      WHERE
        ch.entity_id = ch.author_id AND 
        rc.entity_id <> rc.uid  AND 
        ch.sys_id > rc.ref_sys_id AND 
        mt.tag_id = p.tag_id), 0) room_count   
  FROM 
    tag p
  WHERE parent_tag_id IS NULL
  ORDER BY 
    CASE WHEN  LCASE(_order) = 'asc' THEN position END ASC,
    CASE WHEN  LCASE(_order) = 'desc' THEN position END DESC LIMIT _offset, _range;

END$


DROP PROCEDURE IF EXISTS `tag_get_next_old`$
CREATE PROCEDURE `tag_get_next_old`(
    IN _key  VARCHAR(50),
    IN _search VARCHAR(255), -- ,
    IN _order   VARCHAR(20),
    IN  _page INT(6)
)

BEGIN
    DECLARE _tag_id VARCHAR(16);
    DECLARE _root_tag_id VARCHAR(16);
    DECLARE _lvl INT(4);    
    DECLARE _is_any_child int(1) default 0;
    DECLARE _range bigint;
    DECLARE _offset bigint;
    -- DECLARE _order   VARCHAR(20) default 'asc';

   CALL pageToLimits(_page, _offset, _range);

    DROP TABLE IF EXISTS _tag;
    CREATE TEMPORARY TABLE _tag(`tag_id` varchar(16) NOT NULL,`root_tag_id` varchar(16)  NULL,
    `is_checked` boolean default 0 ); 

    

    IF (_search IS NULL OR _search = "") THEN

      IF (_key IS NULL OR _key ='' OR _key ='0') THEN
          
        SELECT 
          _page as `page`,
          tag_id,
          parent_tag_id,
          name,
          IFNULL((SELECT  1  FROM tag c WHERE c.parent_tag_id = p.tag_id LIMIT 1),0) is_any_child,
          position
        FROM 
          tag p
        WHERE parent_tag_id IS NULL
        ORDER BY 
          CASE WHEN  LCASE(_order) = 'asc' THEN position END ASC,
          CASE WHEN  LCASE(_order) = 'desc' THEN position END DESC LIMIT _offset, _range;

      ELSE  
        SELECT tag_id FROM tag WHERE tag_id = _key or name = _key INTO _tag_id;
        
        SELECT 
          _page as `page`,
          tag_id,
          parent_tag_id,
          name,
          IFNULL((SELECT  1  FROM tag c WHERE c.parent_tag_id = p.tag_id LIMIT 1),0) is_any_child,
          position
        FROM 
          tag p
        WHERE parent_tag_id = _tag_id
        ORDER BY 
          CASE WHEN  LCASE(_order) = 'asc' THEN position END ASC,
          CASE WHEN  LCASE(_order) = 'desc' THEN position END DESC
          LIMIT _offset, _range;
          
      END IF;
    ELSE

      IF (_key IS NULL OR _key ='' OR _key ='0') THEN
        INSERT INTO _tag (tag_id,root_tag_id) SELECT tag_id,tag_id FROM tag WHERE parent_tag_id IS NULL;
      ELSE 
        SELECT tag_id FROM tag WHERE tag_id = _key or name = _key INTO _tag_id;
        INSERT INTO _tag (tag_id,root_tag_id) SELECT tag_id,tag_id FROM tag WHERE parent_tag_id =_tag_id;
      END IF ;

          
      WHILE (IFNULL((SELECT 1 FROM _tag  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO
        SELECT tag_id,root_tag_id  FROM _tag WHERE is_checked = 0 LIMIT 1  INTO _tag_id,_root_tag_id;
        INSERT INTO _tag (tag_id,root_tag_id) SELECT tag_id ,_root_tag_id FROM tag WHERE  parent_tag_id = _tag_id;
        UPDATE _tag SET is_checked =  1 WHERE tag_id =_tag_id; 
        SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
      END WHILE;
      
      SELECT NULL INTO _tag_id; 
      SELECT tag_id FROM tag WHERE tag_id = _key or name = _key INTO _tag_id;
  
      SELECT 
        _page as `page`,
        t.tag_id , 
        t.parent_tag_id, 
        name,
        IFNULL((SELECT  1  FROM tag c WHERE c.parent_tag_id = t.tag_id LIMIT 1),0) is_any_child,
        position
      FROM 
      tag t        
      WHERE 1=1
      AND EXISTS (
        SELECT 1 FROM _tag at  
        INNER JOIN map_tag mt ON at.tag_id = mt.tag_id 
        WHERE EXISTS (SELECT 1 FROM chat c where c.entity_id =mt.id AND message LIKE CONCAT('%', _search, '%'))
        AND   root_tag_id = t.tag_id
      )
      AND IFNULL(t.parent_tag_id,'-99' ) = IFNULL(_tag_id, '-99') 
      
      ORDER BY 
        CASE WHEN LCASE(_order) = 'asc' THEN name END ASC,
        CASE WHEN LCASE(_order) = 'desc' THEN name END DESC
        LIMIT _offset, _range;
      

    
    END IF;
 
END$



DROP PROCEDURE IF EXISTS `tag_chk_child`$
CREATE PROCEDURE `tag_chk_child`(
    _tag_id  VARCHAR(16),
    _chk_id VARCHAR(16)
)

BEGIN
   
    DECLARE _lvl INT(4);    
    DECLARE _is_any_child int(1) default 0;

     DROP TABLE IF EXISTS _tag;
     CREATE TEMPORARY TABLE _tag(
            `tag_id` varchar(16) NOT NULL,
            `is_checked` boolean default 0
     );
    
     INSERT INTO _tag (tag_id) SELECT _tag_id;
     WHILE (IFNULL((SELECT 1 FROM _tag  WHERE  is_checked = 0 LIMIT 1 ),0)  = 1 ) AND IFNULL(_lvl,0) < 1000 DO
            SELECT tag_id  FROM _tag WHERE is_checked = 0 LIMIT 1  INTO _tag_id;
            INSERT INTO _tag (tag_id) SELECT tag_id FROM tag WHERE  parent_tag_id = _tag_id;
            UPDATE _tag SET is_checked =  1 WHERE tag_id =_tag_id; 
            SELECT IFNULL(_lvl,0) + 1 INTO _lvl;
     END WHILE; 


    
        SELECT * FROM tag WHERE tag_id IN (SELECT tag_id FROM _tag WHERE tag_id = _chk_id );
 
END$


DROP PROCEDURE IF EXISTS `tag_assign`$
CREATE PROCEDURE `tag_assign`(
    _tag_id VARCHAR(50),
    _parent_id VARCHAR(16)
)
BEGIN
   
     
    UPDATE tag SET parent_tag_id = _parent_id WHERE tag_id = _tag_id;
    
    CALL tag_get_next(_parent_id, '', 'asc');

END$


DROP PROCEDURE IF EXISTS `tag_rename`$
CREATE PROCEDURE `tag_rename`(
    _tag_id VARCHAR(50),
    _name VARCHAR(255)   
)
BEGIN
    
   SELECT unique_tagname(_name,_tag_id) INTO _name;

   UPDATE tag SET name = _name WHERE tag_id = _tag_id;

  CAll tag_get (_tag_id,null);

END$

-- DROP PROCEDURE IF EXISTS `tag_reposition`$
-- CREATE PROCEDURE `tag_reposition`(
--     _tag_id VARCHAR(50),
--     _pos int(11) unsigned
-- )
-- BEGIN
--     DECLARE  _frmpos int(11) unsigned;
--     DECLARE  _topos int(11) unsigned;

--     SELECT position FROM tag WHERE tag_id =_tag_id INTO _frmpos ;
--     SELECT position FROM tag WHERE position =_pos INTO _topos ;
    
--     IF _frmpos > _topos THEN
--         UPDATE tag SET position=position + 1 WHERE position 
--         BETWEEN  _topos  AND _frmpos -1;
--         UPDATE tag SET position=_topos WHERE tag_id = _tag_id ;
--     END IF ;
    
--     IF _frmpos < _topos THEN
--         UPDATE tag SET position=position - 1 WHERE position 
--         BETWEEN _frmpos +1 AND _topos;
--         UPDATE tag SET position=_topos WHERE tag_id = _tag_id ;
--     END IF ;
    
--     CALL tag_get (_tag_id,null);

-- END$



DROP PROCEDURE IF EXISTS `tag_reposition`$
CREATE PROCEDURE `tag_reposition`(
  IN _tags MEDIUMTEXT
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  DROP TABLE IF EXISTS __tmp_position;
  CREATE TEMPORARY TABLE __tmp_position(
    `position` INTEGER,
    `id` varchar(16) DEFAULT NULL
  ); 

  WHILE _i < JSON_LENGTH(_tags) DO 
    -- UPDATE media SET rank = _i 
    --   WHERE id = JSON_UNQUOTE(JSON_EXTRACT(_nodes, CONCAT("$[", _i, "]")));
    INSERT INTO __tmp_position 
      SELECT _i, JSON_UNQUOTE(JSON_EXTRACT(_tags, CONCAT("$[", _i, "]")));
    SELECT _i + 1 INTO _i;
  END WHILE;
  UPDATE tag m INNER JOIN __tmp_position t ON m.tag_id=t.id SET m.position = t.position ;
  SELECT * FROM __tmp_position;
END $



DROP PROCEDURE IF EXISTS `my_contact_tag_delete`$
DROP PROCEDURE IF EXISTS `my_tag_delete`$
CREATE PROCEDURE `my_tag_delete`(
  IN  _entity_id VARCHAR(16), 
  IN  _tag_id VARCHAR(16)  
)
BEGIN
 
  IF _tag_id IN ('',  '0') THEN 
   SELECT NULL INTO  _tag_id;
  END IF;
  
  IF _tag_id IS NULL THEN
    DELETE FROM map_tag WHERE id = _entity_id;
  ELSE 
    DELETE FROM map_tag WHERE tag_id =_tag_id AND  id = _entity_id;
  END IF;  

END$



DROP PROCEDURE IF EXISTS `my_contact_tag_add`$
DROP PROCEDURE IF EXISTS `my_tag_add`$
CREATE PROCEDURE `my_tag_add`(
  IN  _entity_id VARCHAR(16), 
  IN  _tags  MEDIUMTEXT
)
BEGIN
 DECLARE _idx INTEGER DEFAULT 0;
 DECLARE _tag_id VARCHAR(16);
 DECLARE _length INTEGER DEFAULT 0;
 DECLARE _tag_time int(11) unsigned;
 DECLARE _category VARCHAR(50) DEFAULT 'contact';
 
 SELECT 'group' FROM media where id = _entity_id INTO  _category;

 SELECT UNIX_TIMESTAMP() INTO _tag_time; 
 
 SELECT  JSON_LENGTH(_tags)  INTO _length;

 WHILE _idx < _length  DO 
   SELECT JSON_UNQUOTE(JSON_EXTRACT(_tags, CONCAT("$[", _idx, "]"))) INTO _tag_id;
    INSERT INTO map_tag(tag_id,id, category,ctime) 
    SELECT _tag_id,_entity_id,_category ,_tag_time ON DUPLICATE KEY UPDATE ctime =_tag_time , tag_id=_tag_id;
    SELECT _idx + 1 INTO _idx;
  END WHILE;

  CALL my_tag_get (_entity_id);

END$


DROP PROCEDURE IF EXISTS `my_contact_tag_get`$
DROP PROCEDURE IF EXISTS `my_tag_get`$
CREATE PROCEDURE `my_tag_get`(
  IN  _entity_id VARCHAR(16)
)
BEGIN

  SELECT t.* FROM 
  tag t 
  INNER JOIN map_tag mt ON t.tag_id = mt.tag_id 
  WHERE mt.id =  _entity_id;  
END$



DROP FUNCTION IF EXISTS `unique_tagname`$
CREATE FUNCTION `unique_tagname`(
  _tag_name VARCHAR(255),
  _chk_tag_id VARCHAR(50)
)
RETURNS VARCHAR(1024) DETERMINISTIC
BEGIN
  DECLARE _r VARCHAR(1024);
  DECLARE _count INT(8) DEFAULT 0;
  DECLARE _depth INT(4) DEFAULT 0;

  IF _chk_tag_id IN ('',  '0') THEN 
   SELECT NULL INTO  _chk_tag_id;
  END IF;

  SELECT count(*) FROM tag WHERE name = _tag_name   AND tag_id <> IFNULL(_chk_tag_id,'xxxxxx')
  INTO _count;
 
  IF _count = 0 THEN 
    SELECT _tag_name INTO _r;
  ELSE 
      WHILE _depth  < 1000 AND _count > 0 DO 
            SELECT _depth + 1 INTO _depth;
            SELECT CONCAT(_tag_name, " (", _depth, ")") INTO _r;
            SELECT count(*) FROM tag WHERE name = _r  AND tag_id <> IFNULL(_chk_tag_id,'xxxxxx')
            INTO _count;

      END WHILE;  
  END IF;   
  RETURN _r;
END$


DELIMITER ;
