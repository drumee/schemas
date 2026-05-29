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
DECLARE _last_read_id INT(11) UNSIGNED DEFAULT 0;

  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _uid;

  SELECT IFNULL(last_read_id, 0) INTO _last_read_id
  FROM mfs_ack
  WHERE user_id = _uid;

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node (
      resource_id  VARCHAR(16) CHARACTER SET ascii,
      entity_id VARCHAR(16) CHARACTER SET ascii,
      hub_id VARCHAR(16) CHARACTER SET ascii,
      ctime  INT(11) ,
      area  VARCHAR(16),
      category VARCHAR(16),
      last_id BIGINT,
      author_id VARCHAR(16) CHARACTER SET ascii
   );

   --  contact invite (excludes contacts the user already dismissed)
   INSERT INTO _show_node
   SELECT
      ci.id, d.id, _uid, mtime, 'personal', 'contact', ci.sys_id, d.id
   FROM
   contact ci
   INNER JOIN yp.drumate d ON d.id = ci.entity
   WHERE ((ci.status="received") OR (ci.status="informed") OR (ci.status="invitation"))
     AND ci.dismissed_at IS NULL;

   --  individual P2P chat (new p2p_channel/p2p_time/p2p_read design)
   INSERT INTO _show_node
   SELECT
      pt.peer_id, pt.peer_id, _uid, pt.ref_ctime, 'personal', 'chat', pt.ref_ctime, pt.peer_id
   FROM
      p2p_time pt
   INNER JOIN yp.drumate du ON du.id = pt.peer_id
   LEFT JOIN p2p_read pr ON pr.peer_id = pt.peer_id AND pr.uid = _uid
   WHERE pt.ref_ctime > IFNULL(pr.ref_ctime, 0);

   --  team chat  & hub media
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

      SET @sql=  CONCAT(
         "INSERT INTO _show_node
         SELECT c.message_id,'", _nid ,"','",_nid, "' As hub_id ,c.ctime,'", _area, "','teamchat', c.sys_id, c.author_id  FROM ", _db_name ,".channel c WHERE
         c.sys_id > (SELECT  ref_sys_id FROM ", _db_name ,".read_channel WHERE uid ='", _uid ,"')" ) ;
      IF @sql IS NOT NULL THEN
         EXECUTE IMMEDIATE @sql;
      END IF;

      -- ctime tracks the latest matching mfs_changelog (not m.upload_time),
      -- and all three subqueries exclude rows the user dismissed via
      -- activity.dismiss — otherwise a dismissed event keeps the file's
      -- rollup alive on every reload.
      -- author_id is resolved AFTER aggregation by joining
      -- yp.mfs_changelog on b.last_id in the final SELECT — cheaper than a
      -- third correlated subquery per file (the timestamp + id ones are
      -- already two passes). NULL here is fine; the outer JOIN fills it.
      SET @s1 = CONCAT(
         "INSERT INTO _show_node
         SELECT m.id, '", _nid, "', '", _nid, "', (
            SELECT MAX(ch.timestamp) FROM yp.mfs_changelog ch
             LEFT JOIN mfs_dismissed dm ON dm.changelog_id = ch.id AND dm.user_id = '", _uid, "'
             WHERE ch.hub_id = '", _nid, "'
               AND ch.uid != '", _uid, "'
               AND JSON_VALUE(ch.src, '$.nid') = m.id
               AND dm.changelog_id IS NULL
         ), '", _area, "', 'media', (
            SELECT MAX(ch.id) FROM yp.mfs_changelog ch
             LEFT JOIN mfs_dismissed dm ON dm.changelog_id = ch.id AND dm.user_id = '", _uid, "'
             WHERE ch.hub_id = '", _nid, "'
               AND ch.uid != '", _uid, "'
               AND JSON_VALUE(ch.src, '$.nid') = m.id
               AND dm.changelog_id IS NULL
         ), NULL
         FROM ", _db_name, ".media m
         WHERE m.file_path NOT REGEXP '^/__(chat|trash)__'
           AND m.category != 'root'
           AND EXISTS (
              SELECT 1 FROM yp.mfs_changelog ch
              LEFT JOIN mfs_dismissed dm ON dm.changelog_id = ch.id AND dm.user_id = '", _uid, "'
              WHERE ch.hub_id = '", _nid, "'
                AND ch.uid != '", _uid, "'
                AND ch.id > ", _last_read_id, "
                AND JSON_VALUE(ch.src, '$.nid') = m.id
                AND dm.changelog_id IS NULL
           )"
      );
      IF @s1 IS NOT NULL THEN
         PREPARE stmt FROM @s1;
         EXECUTE stmt;
         DEALLOCATE PREPARE stmt;
      END IF;

      UPDATE _my_hubs SET is_checked = 1 WHERE id = _nid ;
      SELECT  NULL INTO  _nid;
      SELECT id, db_name,area FROM _my_hubs WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name,_area; 
   END WHILE;

 
   --  ticket chat
   SELECT domain_id FROM yp.privilege WHERE uid = _uid INTO _domain_id;
   SELECT 1  FROM yp.sys_conf WHERE  conf_key = 'support_domain' 
   AND conf_value =_domain_id INTO _is_support;


   IF _is_support <> 1 THEN 

      SELECT h.id FROM 
      yp.hub h INNER JOIN yp.entity e on e.id=h.id
      WHERE h.owner_id=_uid AND `serial`=0
      INTO _wicket_id;

      SELECT db_name FROM yp.entity WHERE id=_wicket_id INTO _wicket_db_name;

      SET @s2 = CONCAT("
         INSERT INTO _show_node
         SELECT
            t.ticket_id, t.ticket_id, 'Support Ticket', c.ctime, 'personal', 'ticket', c.sys_id, c.author_id
         FROM
            yp.ticket t
         INNER JOIN ", _wicket_db_name ,". map_ticket mt  ON  mt.ticket_id = t.ticket_id
         INNER JOIN ", _wicket_db_name ,".channel c ON mt.message_id = c.message_id
         LEFT JOIN yp.read_ticket_channel rtc on rtc.ticket_id = mt.ticket_id AND rtc.uid =?
         WHERE t.uid =? AND c.sys_id > IFNULL(rtc.ref_sys_id,0)"
      );
      IF @s2 IS NOT NULL THEN
         PREPARE stmt FROM @s2;
         EXECUTE stmt USING _uid,_uid;
         DEALLOCATE PREPARE stmt;
      END IF;
   ELSE

      -- Support-agent branch: no channel JOIN here (regular branch reads
      -- c.ctime from the wicket DB's channel table; this branch only has
      -- yp.ticket). Use t.utime as the closest available activity timestamp.
      INSERT INTO _show_node
      SELECT
         t.ticket_id, t.ticket_id, 'Support Ticket', t.utime, 'personal', 'ticket', t.last_sys_id, NULL
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
      coalesce(c.id,  d.id,dmu.id,  CASE WHEN b.hub_id = 'Support Ticket' THEN b.entity_id ELSE b.hub_id END  ) key_id,
      coalesce(c.firstname, d.firstname, dmu.email) firstname,
      coalesce(c.lastname, d.lastname, dmu.email) lastname,
      IF ( b.hub_id <>'Support Ticket' , (coalesce( IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,coalesce(ce.email,d.email,dmu.email),
      CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,  h.name )), b.entity_id  )surname,
      coalesce(ce.email,d.email,dmu.email) email,
      c.status status,
      b.hub_id hub_id,
      b.ctime,
      b.category,
      b.cnt,
      b.area,
      b.last_id,
      COALESCE(b.author_id, mcl.uid) author_id,
      ad.firstname author_firstname,
      ad.lastname author_lastname,

      (SELECT GROUP_CONCAT(t.tag_id) FROM
      tag t INNER JOIN map_tag mt ON t.tag_id = mt.tag_id
      WHERE mt.id = coalesce(c.id,  d.id,dmu.id,  CASE WHEN b.hub_id = 'Support Ticket' THEN b.entity_id ELSE b.hub_id END  )) as tag_id
   FROM
   (SELECT
      count(1) cnt, entity_id, hub_id, category, max(ctime) ctime, area, max(last_id) last_id,
      MAX(author_id) author_id
   FROM  _show_node
   GROUP BY entity_id,hub_id,category,area ) b
   LEFT JOIN yp.hub h ON h.id = b.hub_id
   LEFT JOIN yp.dmz_user dmu ON b.entity_id = dmu.id
   LEFT JOIN yp.drumate d ON b.entity_id = d.id
   LEFT JOIN contact c ON  b.entity_id = c.uid  OR  b.entity_id = c.entity
   LEFT JOIN contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1
   -- For media rollups (author_id is NULL in _show_node), resolve the latest
   -- uploader by joining mfs_changelog on the aggregated last_id. PRIMARY KEY
   -- lookup → O(1) per row, cheap.
   LEFT JOIN yp.mfs_changelog mcl ON b.category = 'media' AND mcl.id = b.last_id
   LEFT JOIN yp.drumate ad ON ad.id = COALESCE(b.author_id, mcl.uid)
   ORDER BY b.ctime DESC;


END$
DELIMITER ;