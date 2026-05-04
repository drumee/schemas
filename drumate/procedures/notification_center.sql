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
      ctime  INT(11) ,
      area  VARCHAR(16),
      category VARCHAR(16)

   );

   --  contact invite
   INSERT INTO _show_node
   SELECT 
      ci.id  ,d.id ,_uid , mtime,'personal' ,'contact'
   FROM 
   contact ci 
   INNER JOIN yp.drumate d ON d.id = ci.entity
   WHERE (ci.status="received") OR (ci.status="informed") OR (ci.status="invitation");

   --  individual chat
   INSERT INTO _show_node
   SELECT   
      ch.message_id, ch.author_id , _uid ,ch.ctime , 'personal' , 'chat'   
   FROM    
      channel ch    
   INNER JOIN read_channel rc ON ch.author_id = rc.entity_id
   INNER JOIN contact c ON c.uid = ch.author_id
   WHERE rc.entity_id <> rc.uid AND ch.sys_id > rc.ref_sys_id;

 

   SELECT  
      c.id contact_id,
      d.id drumate_id,
      dmu.id guest_id,
      coalesce(c.id,  d.id, dmu.id,  hub_id ) key_id,
      coalesce(c.firstname, d.lastname, dmu.email) firstname,  
      coalesce(c.lastname, d.lastname, dmu.email) lastname,
      coalesce(ce.email,d.email,dmu.email) email,
      c.status status,
      b.hub_id hub_id,
      b.ctime,
      b.category,
      b.cnt,
      b.area,
            
      (SELECT GROUP_CONCAT(t.tag_id) FROM 
      tag t INNER JOIN map_tag mt ON t.tag_id = mt.tag_id 
      WHERE mt.id = coalesce(c.id,  d.id,dmu.id,  CASE WHEN hub_id = 'Support Ticket' THEN entity_id ELSE hub_id END  )) as tag_id
   FROM 
   (SELECT 
      count(1) cnt ,entity_id,hub_id,category,max(ctime) ctime ,area  
   FROM  _show_node 
   GROUP BY entity_id,hub_id,category,area ) b 
   --  LEFT JOIN yp.hub h on h.id = b.hub_id
   LEFT JOIN yp.hub h ON h.id = b.hub_id   
   LEFT JOIN yp.dmz_user dmu ON b.entity_id = dmu.id
   LEFT JOIN yp.drumate d ON b.entity_id = d.id 
   LEFT JOIN contact c ON  b.entity_id = c.uid  OR  b.entity_id = c.entity
   LEFT JOIN contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1
   ORDER BY b.ctime DESC;


END$
DELIMITER ;
