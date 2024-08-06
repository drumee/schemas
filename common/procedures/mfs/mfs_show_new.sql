DELIMITER $

-- ==============================================================
-- mfs_show_new
-- List files + directories under directory identified by node_id
-- ==============================================================
DROP PROCEDURE IF EXISTS `mfs_show_new`$
CREATE PROCEDURE `mfs_show_new`(
  IN _node_id VARCHAR(16) CHARACTER SET utf8,
  IN _uid VARCHAR(16),
  IN _page    TINYINT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _tempid VARCHAR(16);
  DECLARE _category VARCHAR(16);
  DECLARE _lvl INT;
  DECLARE _hub_db_name VARCHAR(255);
  DECLARE _hubs MEDIUMTEXT DEFAULT NULL;
  DECLARE _hub_id VARCHAR(16);
  DECLARE _type VARCHAR(255);
    CALL pageToLimits(_page, _offset, _range);
    SELECT type,id FROM yp.entity WHERE db_name = database() INTO  _type,_hub_id;
  
    DROP TABLE IF EXISTS __output_count; 
    CREATE TEMPORARY TABLE `__output_count` (
      seq  int NOT NULL AUTO_INCREMENT,
      id varchar(16),
      owner_id varchar(16) DEFAULT NULL, 
      hub_id varchar(16) DEFAULT NULL, 
      preview varchar(1000),
      category enum('media','chat') DEFAULT 'media',
      PRIMARY KEY `seq`(`seq`),
      UNIQUE KEY `id`(`hub_id`,`id`)
    );


    DROP TABLE IF EXISTS _show_node; 
    CREATE TEMPORARY TABLE _show_node (
     `seq`  int NOT NULL AUTO_INCREMENT,
     `id` varchar(16),
     `parent_id` varchar(16), 
     `category` varchar(16) ,
      PRIMARY KEY `seq`(`seq`) 
    );

    INSERT INTO _show_node 
    (id, parent_id ,category)
    WITH RECURSIVE mytree AS 
    ( 
      SELECT id, parent_id ,category
      FROM media WHERE id = _node_id 
        AND category IN('hub', 'folder')
        UNION ALL
      SELECT m.id,m.parent_id ,m.category
      FROM media AS m JOIN mytree AS t ON m.parent_id = t.id
        AND m.category IN('hub', 'folder')
    )SELECT id, parent_id ,category FROM mytree;
 
     
    SELECT MAX(seq) FROM _show_node  INTO _lvl; 
    SELECT id,category FROM _show_node WHERE seq = _lvl 
      INTO _tempid  ,_category;


    WHILE ( _lvl >= 1 AND  _tempid IS NOT NULL) DO
      IF (_category = 'hub') THEN
        SELECT db_name FROM yp.entity WHERE id = _tempid
        INTO _hub_db_name; 

 
        SET @s = CONCAT(
            "REPLACE INTO __output_count (id, owner_id, hub_id, preview, category) ",
            "SELECT message_id, author_id, ?, SUBSTRING(`message`, 1, 80), 'chat' FROM 
            ", _hub_db_name,".channel where sys_id >(SELECT 
            IFNULL((SELECT ref_sys_id FROM ", _hub_db_name,".read_channel 
            WHERE uid = ?),0))"
          );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _hub_id,  _uid;
        DEALLOCATE PREPARE stmt;

        SET @s = CONCAT(
            "REPLACE INTO __output_count (id, owner_id, hub_id, preview) ",
            "SELECT id, owner_id, ?, file_path FROM ", _hub_db_name ,
            ".media WHERE file_path not REGEXP '^/__(chat|trash)__' AND ",
            "is_new(metadata, owner_id, ?)"
         );
        PREPARE stmt FROM @s;
        EXECUTE stmt USING _tempid,_uid;
        DEALLOCATE PREPARE stmt;
      END IF;
      SELECT _lvl - 1  INTO _lvl; 
      SELECT NULL, NULL INTO _tempid,_category;
      SELECT id,category FROM _show_node WHERE seq = _lvl 
      INTO _tempid,_category;
    END WHILE;
 
    REPLACE INTO __output_count (id, owner_id, hub_id, preview)
    SELECT  m.id, m.owner_id, _hub_id, file_path FROM _show_node 
    INNER JOIN media m USING(id)  
    WHERE JSON_EXISTS(m.metadata, '$._seen_') AND 
    NOT JSON_EXISTS(metadata, CONCAT('$._seen_.', _uid));

  IF _type='hub' AND _category IN('hub', 'folder') THEN 
    REPLACE INTO __output_count (id, owner_id, hub_id, preview, category) 
    SELECT message_id, author_id, _hub_id, SUBSTRING(`message`, 1, 80), 'chat' FROM 
    channel where sys_id >(SELECT 
    IFNULL((SELECT ref_sys_id FROM read_channel WHERE uid = _uid),0));
  END IF;


  DROP TABLE IF EXISTS __output; 
  CREATE TEMPORARY TABLE __output  AS 
  SELECT o.category, COUNT(DISTINCT o.id) new_media, 0 new_message,
    IF(firstname IS NULL AND lastname IS NULL, email, 
      CONCAT(IFNULL(firstname, ''), ' ', IFNULL(lastname, ''))
    ) fullname, 
    IFNULL(firstname, '') firstname,
    IFNULL(lastname, '') lastname,
    hh.name hubname,
    GROUP_CONCAT(
      JSON_OBJECT(
        "hub_id", o.hub_id, 
        "nid", o.id,
        "type", o.category,
        "preview", o.preview
    )) nodes,
    ',{}' messages,
    o.owner_id `uid` 
    FROM __output_count o 
    INNER JOIN yp.drumate d ON o.owner_id = d.id 
    LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
    WHERE o.owner_id != _uid AND o.category ='media' GROUP BY(d.id)
    -- AND o.category ='media'
    -- GROUP BY(d.id)
  UNION
  SELECT o.category, COUNT(DISTINCT o.id) new_media, 0 new_message,
    d.email fullname, 
    IFNULL(d.email, '') firstname,
    IFNULL(d.email, '') lastname,
    hh.name hubname,
    GROUP_CONCAT(
      JSON_OBJECT(
        "hub_id", o.hub_id, 
        "nid", o.id,
        "type", o.category,
        "preview", o.preview
    )) nodes,
    ',{}' messages,
    o.owner_id `uid` 
    FROM __output_count o 
    INNER JOIN yp.dmz_user d ON o.owner_id = d.id 
    LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
    WHERE o.owner_id != _uid AND o.category ='media' GROUP BY(d.id)
  UNION
  SELECT o.category, 0 new_media, COUNT(DISTINCT o.id) new_message, 
    IF(firstname IS NULL AND lastname IS NULL, email, 
      CONCAT(IFNULL(firstname, ''), ' ', IFNULL(lastname, ''))
    ) fullname, 
    IFNULL(firstname, '') firstname,
    IFNULL(lastname, '') lastname,
    hh.name hubname,
    '{},' nodes,
    GROUP_CONCAT(
      JSON_OBJECT(
        "hub_id", o.hub_id, 
        "nid", o.id,
        "type", o.category,
        "preview", o.preview
    )) messages,
    o.owner_id `uid` 
    FROM __output_count o INNER JOIN yp.drumate d ON o.owner_id = d.id 
    LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
    WHERE o.owner_id != _uid AND o.category ='chat' 
    GROUP BY(d.id);
  
  SELECT GROUP_CONCAT(
      nodes, 
      messages
      SEPARATOR '+++'
    ) notifications, 
    SUM(new_message) new_message, 
    SUM(new_media) new_media,
    SUM(new_message) new_chat, 
    SUM(new_media) new_file,
    `uid`,
    hubname,
    fullname,
    firstname,
    lastname
  FROM __output GROUP BY(uid);

  DROP TABLE IF EXISTS __output_count;
  DROP TABLE IF EXISTS _show_node; 
  DROP TABLE IF EXISTS __output; 
END $




-- DROP PROCEDURE IF EXISTS `mfs_show_new`$
-- CREATE PROCEDURE `mfs_show_new`(
--   IN _node_id VARCHAR(1000),
--   IN _uid VARCHAR(16),
--   IN _page    TINYINT(4)
-- )
-- BEGIN
--   DECLARE _range bigint;
--   DECLARE _offset bigint;
--   DECLARE _finished INTEGER DEFAULT 0; 
--   DECLARE _id  VARCHAR(16); 
--   DECLARE _owner_id  VARCHAR(16); 
--   DECLARE _hub_id   VARCHAR(16); 
--   DECLARE _category  VARCHAR(100);
--   DECLARE _kcat  VARCHAR(100);
--   DECLARE _seq  INT ;
--   DECLARE _hub_db_name VARCHAR(255); 
--   DECLARE _hub_name VARCHAR(255); 
--   DECLARE _type VARCHAR(255); 
--   CALL pageToLimits(_page, _offset, _range);  

--   SELECT category FROM  media WHERE  id = _node_id INTO _category; 
--   SELECT type, id, name FROM yp.entity INNER JOIN yp.hub USING(id) WHERE db_name=database() 
--     INTO _type, _hub_id, _hub_name; 

--   DROP TABLE IF EXISTS __output_count; 
--     CREATE TEMPORARY TABLE `__output_count` (
--       seq  int NOT NULL AUTO_INCREMENT,
--       id varchar(16),
--       owner_id varchar(16) DEFAULT NULL, 
--       hub_id varchar(16) DEFAULT NULL, 
--       preview varchar(1000),
--       category enum('media','chat') DEFAULT 'media',
--       PRIMARY KEY `seq`(`seq`),
--       UNIQUE KEY `id`(`hub_id`,`id`)
--     );


--   DROP TABLE IF EXISTS _mytree; 
--     CREATE TEMPORARY TABLE _mytree (
--       seq  int NOT NULL AUTO_INCREMENT,
--       id varchar(16),
--       owner_id varchar(16) DEFAULT NULL, 
--       hub_id varchar(16) DEFAULT NULL, 
--       hub_db_name VARCHAR(255),
--       preview varchar(1000),
--       category  varchar(100),
--       PRIMARY KEY `seq`(`seq`),
--       UNIQUE KEY `id`(`hub_id`,`id`)
--     );


--   INSERT INTO _mytree (id, owner_id, hub_id, category, hub_db_name ) 
--     WITH RECURSIVE mytree AS (
--       SELECT m.id, m.parent_id ,m.owner_id, COALESCE(he.id, me.id) hub_id ,
--       m.category, IFNULL(he.db_name, database()) db_name
--       FROM media m
--         INNER JOIN yp.entity me  ON me.db_name=database()
--         LEFT  JOIN yp.entity he ON m.id = he.id AND m.category IN('hub', 'folder')
--       WHERE 
--       m.file_path not REGEXP '^/__(chat|trash)__' AND
--       m.id = _node_id
--       UNION ALL
--       SELECT m.id,m.parent_id , m.owner_id,COALESCE(he.id,me.id) hub_id,
--       m.category, IFNULL(he.db_name, database()) db_name
--       FROM media AS m 
--       INNER JOIN yp.entity me  ON me.db_name=database()
--       INNER JOIN mytree AS t ON m.parent_id = t.id
--       LEFT  JOIN yp.entity he ON m.id = he.id AND m.category IN('hub', 'folder')
--       WHERE m.file_path not REGEXP '^/__(chat|trash)__'
--     )
--     SELECT id, owner_id, hub_id, category, db_name FROM mytree;

--     -- SELECT id, owner_id, hub_id, category, hub_db_name FROM _mytree;

--     BEGIN
--       DECLARE dbcursor CURSOR FOR SELECT id, owner_id, hub_id, hub_db_name
--         FROM _mytree WHERE category IN('hub');
--       DECLARE CONTINUE HANDLER FOR NOT FOUND SET _finished = 1; 
--       OPEN dbcursor;
--         FETCH dbcursor INTO _id, _owner_id, _hub_id, _hub_db_name; 
--         WHILE NOT _finished DO 
        
--           SELECT name FROM yp.hub WHERE id = _hub_id INTO _hub_name;
--           SET @s = CONCAT(
--             "REPLACE INTO __output_count (id, owner_id, hub_id, preview, category) ",
--             "SELECT message_id, author_id, ?, ?, 'chat' FROM ", _hub_db_name ,
--             ".channel WHERE JSON_EXISTS(metadata, '$._seen_') AND 
--             NOT JSON_EXISTS(metadata, CONCAT('$._seen_.', ?))"
--           );
--           PREPARE stmt FROM @s;
--           EXECUTE stmt USING _hub_id, _hub_name, _uid;
--           DEALLOCATE PREPARE stmt;
          
--           SET @s = CONCAT(
--             "REPLACE INTO __output_count (id, owner_id, hub_id, preview) ",
--             "SELECT id, owner_id, ?, file_path FROM ", _hub_db_name ,
--             ".media WHERE file_path not REGEXP '^/__(chat|trash)__' AND ",
--             "is_new(metadata, owner_id, ?)"
--           );
--           PREPARE stmt FROM @s;
--           EXECUTE stmt USING _hub_id, _uid;
--           DEALLOCATE PREPARE stmt;

--         FETCH dbcursor INTO _id, _owner_id, _hub_id, _hub_db_name;  
--         END WHILE;
--       CLOSE dbcursor;
--     END; 

  
--   REPLACE INTO __output_count (id, owner_id, hub_id, preview) 
--     SELECT m.id, m.owner_id, o.hub_id, file_path FROM 
--       _mytree o INNER JOIN media m on m.id=o.id 
--     WHERE JSON_EXISTS(m.metadata, '$._seen_') AND 
--     NOT JSON_EXISTS(metadata, CONCAT('$._seen_.', _uid));

--   IF _type='hub' AND _category IN('hub', 'folder') THEN 
--     REPLACE INTO __output_count (id, owner_id, hub_id, preview, category) 
--       SELECT message_id, author_id, _hub_id, SUBSTRING(`message`, 1, 80), 'chat' 
--       FROM channel 
--       WHERE JSON_EXISTS(metadata, '$._seen_') AND 
--       NOT JSON_EXISTS(metadata, CONCAT('$._seen_.', _uid));
--       -- GROUP BY(author_id);
--   END IF;

--   DROP TABLE IF EXISTS __output; 
--   CREATE TEMPORARY TABLE __output  AS 
--   SELECT o.category, COUNT(DISTINCT o.id) new_media, 0 new_message,
--     IF(firstname IS NULL AND lastname IS NULL, email, 
--       CONCAT(IFNULL(firstname, ''), ' ', IFNULL(lastname, ''))
--     ) fullname, 
--     IFNULL(firstname, '') firstname,
--     IFNULL(lastname, '') lastname,
--     hh.name hubname,
--     GROUP_CONCAT(
--       JSON_OBJECT(
--         "hub_id", o.hub_id, 
--         "nid", o.id,
--         "type", o.category,
--         "preview", o.preview
--     )) nodes,
--     ',{}' messages,
--     o.owner_id `uid` 
--     FROM __output_count o 
--     INNER JOIN yp.drumate d ON o.owner_id = d.id 
--     LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
--     WHERE o.owner_id != _uid AND o.category ='media' GROUP BY(d.id)
--     -- AND o.category ='media'
--     -- GROUP BY(d.id)
--   UNION
--   SELECT o.category, COUNT(DISTINCT o.id) new_media, 0 new_message,
--     d.email fullname, 
--     IFNULL(d.email, '') firstname,
--     IFNULL(d.email, '') lastname,
--     hh.name hubname,
--     GROUP_CONCAT(
--       JSON_OBJECT(
--         "hub_id", o.hub_id, 
--         "nid", o.id,
--         "type", o.category,
--         "preview", o.preview
--     )) nodes,
--     ',{}' messages,
--     o.owner_id `uid` 
--     FROM __output_count o 
--     INNER JOIN yp.dmz_user d ON o.owner_id = d.id 
--     LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
--     WHERE o.owner_id != _uid AND o.category ='media' GROUP BY(d.id)
--   UNION
--   SELECT o.category, 0 new_media, COUNT(DISTINCT o.id) new_message, 
--     IF(firstname IS NULL AND lastname IS NULL, email, 
--       CONCAT(IFNULL(firstname, ''), ' ', IFNULL(lastname, ''))
--     ) fullname, 
--     IFNULL(firstname, '') firstname,
--     IFNULL(lastname, '') lastname,
--     hh.name hubname,
--     '{},' nodes,
--     GROUP_CONCAT(
--       JSON_OBJECT(
--         "hub_id", o.hub_id, 
--         "nid", o.id,
--         "type", o.category,
--         "preview", o.preview
--     )) messages,
--     o.owner_id `uid` 
--     FROM __output_count o INNER JOIN yp.drumate d ON o.owner_id = d.id 
--     LEFT JOIN yp.hub hh ON o.hub_id = hh.id 
--     WHERE o.owner_id != _uid AND o.category ='chat' 
--     GROUP BY(d.id)
--     LIMIT _offset ,_range;

--   -- SELECT * FROM __output;
--   SELECT GROUP_CONCAT(
--       nodes, 
--       messages
--       SEPARATOR '+++'
--     ) notifications, 
--     SUM(new_message) new_message, 
--     SUM(new_media) new_media,
--     SUM(new_message) new_chat, 
--     SUM(new_media) new_file,
--     `uid`,
--     hubname,
--     fullname,
--     firstname,
--     lastname
--   FROM __output GROUP BY(uid);
-- END $

DELIMITER ;

