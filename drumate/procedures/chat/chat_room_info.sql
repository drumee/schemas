DELIMITER $
/*

  Status : active 

*/

DROP PROCEDURE IF EXISTS `contact_chat_room_info`$
DROP PROCEDURE IF EXISTS `chat_room_info`$
CREATE PROCEDURE `chat_room_info`(
  IN _id VARCHAR(500)
)
BEGIN
  DECLARE _this_hub_id VARCHAR(16);
  DECLARE _uid  VARCHAR(16);
  DECLARE _mail  VARCHAR(500);

    DROP TABLE IF EXISTS _show_node;
    CREATE TEMPORARY TABLE _show_node (
      entity_id  VARCHAR(16) NOT NULL,  
      hub_id VARCHAR(16) NOT null,
      drumate_id  VARCHAR(16)  NULL,
      contact_id  VARCHAR(16)  NULL,
      firstname  VARCHAR(255)  NULL,
      lastname   VARCHAR(255)  NULL,
      display    VARCHAR(255)  NULL,
      room_count INT DEFAULT 0,
      message    mediumtext  NULL,
      ctime INT(11) unsigned,
      flag VARCHAR(500),
      db_name   VARCHAR(500)  NULL,
      status   VARCHAR(255)  DEFAULT  'active',
      is_blocked INT DEFAULT 0,
      is_blocked_me INT DEFAULT 0,
      is_archived INT DEFAULT 0 ,      
      PRIMARY KEY `entity_id`(`entity_id`)
    ); 

    SELECT id,id FROM yp.entity WHERE db_name=DATABASE() INTO  _this_hub_id ,_uid ;
    SELECT email FROM yp.drumate WHERE id = _uid INTO _mail;


    INSERT INTO _show_node
    SELECT
      c.uid  entity_id, 
      _this_hub_id   hub_id,  
      c.uid  drumate_id, 
      c.id contact_id,
      c.firstname,
      c.lastname,
      -- Empty-string firstname/lastname/surname fix (mirror chat_rooms.sql):
      -- the old `coalesce(c.firstname,c.lastname) IS NULL` guard only caught
      -- NULL, so an OAuth/Apple/trial contact with "firstname":"" (empty string,
      -- not NULL) fell through to CONCAT('',' ','') = ' ' -> a whitespace display
      -- that renders as a BLANK name on the single-room (chat_room_info) refresh.
      -- NULLIF(TRIM(...),'') maps both '' and whitespace to NULL so COALESCE
      -- falls through name -> contact email -> drumate email -> drumate id.
      COALESCE(
        NULLIF(TRIM(c.surname), ''),
        NULLIF(TRIM(CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))), ''),
        NULLIF(TRIM(du.firstname), ''),
        NULLIF(TRIM(du.lastname), ''),
        NULLIF(ce.email, ''),
        NULLIF(du.email, ''),
        du.id
      ) as display,
      CASE WHEN IFNULL(pr.ref_ctime, 0) < IFNULL(tc.ref_ctime, 0) THEN 1 ELSE 0 END,
      tc.message,
      tc.ctime , 
      'contact',null,'active',
      CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
      CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me, 
      CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END  is_archived  
    FROM
      contact c
    LEFT JOIN p2p_time tc ON tc.peer_id = c.uid
    LEFT JOIN p2p_read pr ON pr.peer_id = c.uid AND pr.uid = _uid
    LEFT JOIN contact_email ce ON ce.contact_id = c.id  AND ce.is_default = 1  
    INNER JOIN yp.drumate du ON du.id = c.uid
    LEFT JOIN yp.contact_block mycb ON c.id = mycb.contact_id
    LEFT JOIN yp.contact_block hiscb ON (hiscb.owner_id =  c.entity OR hiscb.owner_id = c.uid) 
        AND( hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail ) 
    LEFT JOIN archive_entity ae ON ae.entity_id = c.id
    WHERE c.uid IS NOT NULL
    AND (c.uid = _id OR c.id = _id);


    INSERT INTO _show_node(entity_id,hub_id,display,flag,message,ctime,status, is_archived)
    SELECT tc.peer_id ,_this_hub_id,COALESCE(NULLIF(TRIM(du.fullname), ''), NULLIF(du.email, ''), du.id),'contact',tc.message, tc.ctime,'memory',
    CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END    
    FROM 
    p2p_time tc
    INNER JOIN yp.drumate du ON du.id = tc.peer_id
    INNER JOIN contact c ON IFNULL(c.entity,'1') = tc.peer_id
    LEFT JOIN archive_entity ae ON ae.entity_id = tc.peer_id
    WHERE tc.peer_id NOT IN (SELECT IFNULL(uid,'1') FROM contact)
    AND tc.peer_id IN (SELECT IFNULL(entity,'1') FROM contact)
    AND (tc.peer_id  = _id OR c.id = _id);


    INSERT INTO _show_node(entity_id,hub_id,display,flag,message,ctime,status, is_archived)
    SELECT tc.peer_id ,_this_hub_id,COALESCE(NULLIF(TRIM(du.fullname), ''), NULLIF(du.email, ''), du.id),'contact',tc.message, tc.ctime,'nocontact',
    CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END    
    FROM 
    p2p_time tc
    INNER JOIN yp.drumate du ON du.id = tc.peer_id
    LEFT JOIN archive_entity ae ON ae.entity_id = tc.peer_id
    WHERE  tc.peer_id NOT IN (SELECT IFNULL(uid,'1') FROM contact) 
    AND tc.peer_id  NOT IN (SELECT IFNULL(entity,'1') FROM contact)
    AND tc.peer_id  = _id;



    SELECT 
      entity_id,
      hub_id,
      drumate_id,
      contact_id,
      firstname,
      lastname,
      display,
      room_count,
      message,
      ctime,
      flag,
      status,
      is_blocked,
      is_blocked_me, 
      is_archived 
    FROM _show_node;
   
END $
DELIMITER ;