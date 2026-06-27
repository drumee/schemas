-- File: schemas/drumate/procedures/notification/notification_center_next.sql
DELIMITER $

DROP PROCEDURE IF EXISTS `notification_center_next`$
CREATE PROCEDURE `notification_center_next`()
BEGIN

DECLARE _uid VARCHAR(16) CHARACTER SET ascii;
DECLARE _db_name VARCHAR(500);
DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
DECLARE _domain_id INT;
DECLARE _is_support INT DEFAULT 0 ;
DECLARE _area VARCHAR(500);
DECLARE _wicket_db_name VARCHAR(255);
DECLARE _wicket_id VARCHAR(16);

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node (
      resource_id  VARCHAR(16) CHARACTER SET ascii,
      entity_id VARCHAR(16) CHARACTER SET ascii,
      hub_id VARCHAR(16) CHARACTER SET ascii,
      nid VARCHAR(16) CHARACTER SET ascii,
      parent_id VARCHAR(16) CHARACTER SET ascii,
      filename VARCHAR(128),
      filetype VARCHAR(16),
      item_filetype VARCHAR(16),
      last_id INT(11) UNSIGNED,
      ctime  INT(11) ,
      area  VARCHAR(16),
      category VARCHAR(16)

   );


   INSERT INTO _show_node
   SELECT
      ci.id  ,d.id ,_uid , NULL, NULL, NULL, NULL, NULL, NULL, mtime,'personal' ,'contact'
   FROM
   contact ci
   INNER JOIN yp.drumate d ON d.id = ci.entity
   WHERE (ci.status="received") OR (ci.status="informed") OR (ci.status="invitation");


   INSERT INTO _show_node
   SELECT
      ch.message_id, ch.author_id , _uid , NULL, NULL, NULL, NULL, NULL, NULL, ch.ctime , 'personal' , 'chat'
   FROM
      channel ch
   INNER JOIN read_channel rc ON ch.entity_id= rc.entity_id
   INNER JOIN contact c ON c.uid = ch.entity_id
   WHERE ch.entity_id = ch.author_id  AND  rc.entity_id <> rc.uid  AND  ch.sys_id > rc.ref_sys_id;


   DROP TABLE IF EXISTS _my_hubs;
   CREATE TEMPORARY TABLE _my_hubs  AS
   SELECT m.sys_id , he.id , db_name , he.area
   FROM
   media m
   INNER JOIN yp.entity he ON m.id = he.id
   INNER JOIN yp.hub h ON m.id = h.id
   WHERE category = 'hub' AND extension <> 'dmz'  AND m.status <> 'hidden' ;

   ALTER TABLE _my_hubs ADD `is_checked` boolean default 0 ;

   SELECT id, db_name,area FROM _my_hubs WHERE is_checked =0  LIMIT 1
   INTO _nid, _db_name,_area;

   WHILE _nid IS NOT NULL DO

      -- Per-folder team-chat rollup. nid = the folder a message was posted in
      -- (channel.metadata._scope_nid; NULL for hub-level/legacy chat → groups as
      -- one hub-level row). filename/parent come from that folder's media node so
      -- the activity item shows the folder name and opens it. Unread is per-message
      -- (delivered AND not _seen_), matching channel_list_notifications, so reading
      -- one folder's messages does not clear a sibling folder's mentions.
      -- File-thread CHILD replies (channel.file_thread_id IS NOT NULL) are
      -- excluded here so they do not spam the folder unread count; the folder
      -- shows exactly one unread item per thread (the root system card). Thread
      -- replies still notify via @mention through the separate mention category.
      SET @sql=  CONCAT(
         "INSERT INTO _show_node
         SELECT c.message_id,'", _nid ,"','",_nid, "' As hub_id , JSON_UNQUOTE(JSON_EXTRACT(c.metadata,'$._scope_nid')), sf.parent_id, sf.user_filename, 'folder', NULL, c.sys_id, c.ctime,'", _area, "','teamchat'  FROM ", _db_name ,".channel c LEFT JOIN ", _db_name ,".media sf ON sf.id = JSON_UNQUOTE(JSON_EXTRACT(c.metadata,'$._scope_nid')) WHERE c.status='active' AND c.author_id <> '", _uid ,"' AND JSON_EXISTS(c.metadata,'$._delivered_.", _uid ,"')=1 AND JSON_EXISTS(c.metadata,'$._seen_.", _uid ,"')=0 AND c.file_thread_id IS NULL" ) ;
      EXECUTE IMMEDIATE @sql;

      SET @s = CONCAT(
          " INSERT INTO _show_node
            SELECT m.id, m.owner_id, '" , _nid , "', target.id, target.parent_id, target.user_filename, 'folder', m.category, m.sys_id, m.upload_time,'", _area ,"','media' FROM ", _db_name ,
          ".media m LEFT JOIN ", _db_name ,".media target ON target.id = IF(m.category = 'folder', m.id, m.parent_id) WHERE m.file_path not REGEXP '^/__(chat|trash)__'  AND m.category != 'root' AND
            IFNULL((is_new(m.metadata, m.owner_id, ?)), 0) =1 "
        );
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid;
      DEALLOCATE PREPARE stmt;

      UPDATE _my_hubs SET is_checked = 1 WHERE id = _nid ;
      SELECT  NULL INTO  _nid;
      SELECT id, db_name,area FROM _my_hubs WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name,_area;
   END WHILE;



   SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
   SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain'
   AND conf_value =_domain_id INTO _is_support;


   IF _is_support <> 1 THEN

      SELECT h.id FROM
      yp.hub h INNER JOIN yp.entity e on e.id=h.id
      WHERE h.owner_id=_uid AND `serial`=0
      INTO _wicket_id;

      SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db_name;

      SET @s = CONCAT("
            INSERT INTO _show_node
            SELECT
               t.ticket_id  , t.ticket_id , 'Support Ticket', NULL,NULL,NULL,NULL,NULL,NULL,c.ctime ,'personal','ticket'
            FROM
               yp.ticket t
            INNER JOIN ", _wicket_db_name ,". map_ticket mt  ON  mt.ticket_id = t.ticket_id
            INNER JOIN ", _wicket_db_name ,".channel c ON mt.message_id = c.message_id
            LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid =?
            WHERE t.uid =? AND c.sys_id > IFNULL(rtc.ref_sys_id,0)"

      );
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid,_uid;
      DEALLOCATE PREPARE stmt;

   ELSE

      INSERT INTO _show_node
      SELECT
         t.ticket_id,  t.ticket_id ,'Support Ticket', NULL,NULL,NULL,NULL,NULL,NULL,c.ctime ,'personal','ticket'
      FROM
         yp.ticket t
      LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = t.ticket_id AND rtc.uid = _uid
      WHERE
         t.last_sys_id > IFNULL(rtc.ref_sys_id,0)
         AND CASE WHEN _is_support = 1 THEN t.uid ELSE _uid END = t.uid;

   END IF;


   SELECT
      c.id contact_id,
      d.id drumate_id,
      dmu.id guest_id,
      coalesce(c.id,  d.id,dmu.id,  CASE WHEN hub_id = 'Support Ticket' THEN entity_id WHEN b.category = 'teamchat' THEN COALESCE(b.nid, hub_id) ELSE hub_id END  ) key_id,
      coalesce(c.firstname, d.firstname, dmu.email) firstname,
      coalesce(c.lastname, d.lastname, dmu.email) lastname,
      IF ( hub_id <>'Support Ticket' , (coalesce( IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,coalesce(ce.email,d.email,dmu.email),
      CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,  h.name )), entity_id  )surname,
      coalesce(ce.email,d.email,dmu.email) email,
      c.status status,
      b.hub_id hub_id,
      b.nid,
      b.parent_id,
      b.filename,
      b.filetype,
      b.item_filetype,
      b.last_id,

      b.ctime,
      b.category,
      b.cnt,
      b.area,

      (SELECT GROUP_CONCAT(t.tag_id) FROM
      tag t INNER JOIN map_tag mt ON t.tag_id = mt.tag_id
      WHERE mt.id = coalesce(c.id,  d.id,dmu.id,  CASE WHEN hub_id = 'Support Ticket' THEN entity_id ELSE hub_id END  )) as tag_id
   FROM
   (SELECT
      count(1) cnt ,entity_id,hub_id,category,max(ctime) ctime ,area,
      nid,
      MAX(parent_id) parent_id,
      MAX(filename) filename,
      MAX(filetype) filetype,
      MAX(item_filetype) item_filetype,
      MAX(last_id) last_id
   FROM  _show_node
   GROUP BY entity_id,hub_id,category,area,nid ) b

   LEFT JOIN yp.hub h ON h.id = b.hub_id
   LEFT JOIN yp.dmz_user dmu ON b.entity_id = dmu.id
   LEFT JOIN yp.drumate d ON b.entity_id = d.id
   LEFT JOIN contact c ON  b.entity_id = c.uid  OR  b.entity_id = c.entity
   LEFT JOIN contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1
   ORDER BY b.ctime DESC;


END $

DELIMITER ;
