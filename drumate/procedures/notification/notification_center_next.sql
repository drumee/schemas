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
      category VARCHAR(16),
      -- The uploaded FILE's own name (media rows only; NULL for every other
      -- category). Lets a single-file upload rollup (cnt = 1) show the file name
      -- instead of its destination folder. For cnt > 1 it is ignored and the
      -- folder/workspace name is shown.
      item_filename VARCHAR(128),
      -- The team-chat message author (its poster). NULL for every non-teamchat
      -- category. The teamchat rollup used entity_id = the FOLDER id, so the
      -- final SELECT's identity joins never matched a user → name/avatar came
      -- back empty and the client showed "Someone posted…" with the viewer's own
      -- face. Carrying the real author here lets the rollup resolve the poster's
      -- name (yp.drumate `da` join below) and the client resolve the avatar.
      author_id VARCHAR(16) CHARACTER SET ascii,
      -- 'start' | 'end' for a [[MEETING:...]] system chat message, else NULL.
      -- Drives the "started/ended a meeting in <folder>" wording. A meeting event
      -- takes priority over plain chat in the per-folder rollup (see the aggregate
      -- below), so a start/end is never masked by a later ordinary message.
      meeting_action VARCHAR(8)

   );


   INSERT INTO _show_node
   SELECT
      ci.id  ,d.id ,_uid , NULL, NULL, NULL, NULL, NULL, NULL, mtime,'personal' ,'contact', NULL, NULL, NULL
   FROM
   contact ci
   INNER JOIN yp.drumate d ON d.id = ci.entity
   -- dismissed_at IS NULL: honor notification_dismiss(contact) which sets
   -- contact.dismissed_at. Without it a dismissed contact-invite rollup keeps
   -- reappearing on reload (the pre-R3 notification_center.sql had this filter;
   -- it was dropped in the R3 rewrite).
   WHERE ((ci.status="received") OR (ci.status="informed") OR (ci.status="invitation"))
     AND ci.dismissed_at IS NULL;


   -- Individual P2P chat. p2p messages live in the p2p_channel/p2p_time tables
   -- (NOT `channel`, which holds 0 p2p rows), and reads are tracked in p2p_read
   -- (written by p2p_acknowledge + notification_dismiss(chat)). So unread = peer
   -- activity (p2p_time.ref_ctime) newer than my read pointer (p2p_read.ref_ctime).
   -- last_id carries ref_ctime so notification_dismiss(chat) — which advances
   -- p2p_read.ref_ctime to last_id — clears it. Restores the pre-R3 p2p model;
   -- the channel/read_channel variant matched no p2p rows so chat rollups never
   -- appeared (and could not be dismissed).
   INSERT INTO _show_node
   SELECT
      pt.peer_id, pt.peer_id, _uid, NULL, NULL, NULL, NULL, NULL, pt.ref_ctime, pt.ref_ctime, 'personal', 'chat', NULL, NULL, NULL
   FROM
      p2p_time pt
   INNER JOIN yp.drumate du ON du.id = pt.peer_id
   LEFT JOIN p2p_read pr ON pr.peer_id = pt.peer_id AND pr.uid = _uid
   WHERE pt.ref_ctime > IFNULL(pr.ref_ctime, 0);


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
      -- NULL guard: if this hub's db_name/area is NULL, CONCAT(...) returns NULL
      -- and EXECUTE IMMEDIATE / PREPARE on a NULL string throws ER_PARSE_ERROR
      -- "near 'NULL'". Skip the dynamic execs for such a hub; the loop still
      -- advances below.
      IF _db_name IS NOT NULL AND _area IS NOT NULL THEN
      SET @sql=  CONCAT(
         "INSERT INTO _show_node
         SELECT c.message_id,'", _nid ,"','",_nid, "' As hub_id , JSON_UNQUOTE(JSON_EXTRACT(c.metadata,'$._scope_nid')), sf.parent_id, sf.user_filename, 'folder', NULL, c.sys_id, c.ctime,'", _area, "','teamchat', NULL, c.author_id, CASE WHEN c.message LIKE '[[MEETING:start:%' THEN 'start' WHEN c.message LIKE '[[MEETING:end:%' THEN 'end' ELSE NULL END  FROM ", _db_name ,".channel c LEFT JOIN ", _db_name ,".media sf ON sf.id = JSON_UNQUOTE(JSON_EXTRACT(c.metadata,'$._scope_nid')) WHERE c.status='active' AND c.author_id <> '", _uid ,"' AND JSON_EXISTS(c.metadata,'$._delivered_.", _uid ,"')=1 AND JSON_EXISTS(c.metadata,'$._seen_.", _uid ,"')=0 AND c.file_thread_id IS NULL" ) ;
      EXECUTE IMMEDIATE @sql;

      SET @s = CONCAT(
          " INSERT INTO _show_node
            SELECT m.id, m.owner_id, '" , _nid , "', target.id, target.parent_id, target.user_filename, 'folder', m.category, m.sys_id, m.upload_time,'", _area ,"','media', m.user_filename, NULL, NULL FROM ", _db_name ,
          ".media m LEFT JOIN ", _db_name ,".media target ON target.id = IF(m.category = 'folder', m.id, m.parent_id) WHERE m.file_path not REGEXP '^/__(chat|trash)__'  AND m.category != 'root' AND
            IFNULL((is_new(m.metadata, m.owner_id, ?)), 0) =1 "
        );
      PREPARE stmt FROM @s;
      EXECUTE stmt USING _uid;
      DEALLOCATE PREPARE stmt;
      END IF;

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

      -- NULL guard: a user with no `serial`=0 hub → _wicket_id / _wicket_db_name
      -- is NULL → CONCAT(...) returns NULL → PREPARE on a NULL string throws
      -- ER_PARSE_ERROR "near 'NULL'" (the prod/UAT incident). Only build + run
      -- the ticket query when the wicket DB actually resolved.
      IF _wicket_db_name IS NOT NULL THEN
      SET @s = CONCAT("
            INSERT INTO _show_node
            SELECT
               t.ticket_id  , t.ticket_id , 'Support Ticket', NULL,NULL,NULL,NULL,NULL, c.sys_id, c.ctime ,'personal','ticket', NULL, NULL, NULL
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
      END IF;

   ELSE

      INSERT INTO _show_node
      SELECT
         t.ticket_id,  t.ticket_id ,'Support Ticket', NULL,NULL,NULL,NULL,NULL,NULL,c.ctime ,'personal','ticket', NULL, NULL, NULL
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
      -- Display name for the rollup. For a media upload into the workspace ROOT
      -- the destination "folder" is the root node, whose user_filename is empty
      -- (NULL on some instances, '' on others) — so b.filename is blank and the
      -- client used to fall back through surname to the UPLOADER'S EMAIL. Fall
      -- back to the workspace name (h.name) so a root upload reads "…in
      -- <Workspace>" instead of the uploader email. NULLIF collapses the ''
      -- variant to NULL so COALESCE catches it too. For contact/chat/ticket rows
      -- b.hub_id is NULL → h.name is NULL → no change.
      COALESCE(NULLIF(b.filename, ''), h.name) filename,
      b.filetype,
      b.item_filetype,
      b.item_filename,
      b.last_id,

      b.ctime,
      b.category,
      b.cnt,
      b.area,
      -- Actor identity for team-chat rollups (NULL for other categories). The
      -- server maps author_id/author_firstname/author_lastname and the client
      -- prefers them for both the sender name and the avatar, so this fixes both
      -- "Someone posted…" and the wrong (viewer's own) avatar. meeting_action lets
      -- the client render "started/ended a meeting in <folder>".
      b.author_id author_id,
      da.firstname author_firstname,
      da.lastname author_lastname,
      b.meeting_action meeting_action,

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
      MAX(last_id) last_id,
      MAX(item_filename) item_filename,
      -- Meeting takes priority: the LATEST [[MEETING]] event's action for this
      -- folder if any exists, else NULL. GROUP_CONCAT skips NULLs, so this is the
      -- newest non-null meeting_action — a later ordinary chat message cannot mask
      -- a start/end. group_concat_max_len truncation is harmless: we only read the
      -- first (newest) element via SUBSTRING_INDEX.
      SUBSTRING_INDEX(GROUP_CONCAT(meeting_action ORDER BY ctime DESC, last_id DESC),',',1) meeting_action,
      -- Actor for the rollup. When a meeting exists → the latest meeting event's
      -- author (so "<X> started/ended a meeting"); otherwise the latest message's
      -- author (so "<X> posted"). last_id (channel sys_id) is unique per message,
      -- so the shared ORDER BY is deterministic and this pick agrees with
      -- meeting_action above. NULL for non-teamchat groups (author_id all NULL).
      COALESCE(
        SUBSTRING_INDEX(GROUP_CONCAT(IF(meeting_action IS NOT NULL, author_id, NULL) ORDER BY ctime DESC, last_id DESC),',',1),
        SUBSTRING_INDEX(GROUP_CONCAT(author_id ORDER BY ctime DESC, last_id DESC),',',1)
      ) author_id
   FROM  _show_node
   GROUP BY entity_id,hub_id,category,area,nid ) b

   LEFT JOIN yp.hub h ON h.id = b.hub_id
   LEFT JOIN yp.dmz_user dmu ON b.entity_id = dmu.id
   LEFT JOIN yp.drumate d ON b.entity_id = d.id
   -- Resolve the team-chat actor's canonical name from the author_id picked in the
   -- aggregate above (separate alias from `d`, which joins on entity_id = folder).
   LEFT JOIN yp.drumate da ON da.id = b.author_id
   LEFT JOIN contact c ON  b.entity_id = c.uid  OR  b.entity_id = c.entity
   LEFT JOIN contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1
   ORDER BY b.ctime DESC;


END $

DELIMITER ;
