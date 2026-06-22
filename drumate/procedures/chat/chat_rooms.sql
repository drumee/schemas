DELIMITER $
/*

  Status : active 

*/

DROP PROCEDURE IF EXISTS `chat_rooms`$
CREATE PROCEDURE `chat_rooms`(
  IN _key VARCHAR(500), 
  IN _tag_id  VARCHAR(16) CHARACTER SET ascii, 
  IN _flag VARCHAR(500),
  IN _option VARCHAR(20),
  IN _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _lvl INT(4);
  DECLARE _this_hub_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _nid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _db_name VARCHAR(500);
  DECLARE _temp_result JSON;
  DECLARE _read_cnt INT;
  DECLARE _attachment mediumtext;
  DECLARE _metadata JSON;
  DECLARE _ctime INT(11) unsigned;
  DECLARE _message mediumtext;
  DECLARE _has_mention INT DEFAULT 0;
  DECLARE _temp_nid VARCHAR(16) CHARACTER SET ascii;

  DECLARE _uid  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _mail  VARCHAR(500);
  DECLARE _domain_id INTEGER;

  SELECT id,id FROM yp.entity WHERE db_name=DATABASE() INTO  _this_hub_id ,_uid ;
  SELECT email FROM yp.drumate WHERE id = _uid INTO _mail;
  SELECT domain_id FROM yp.drumate WHERE id = _uid INTO _domain_id;
  
  CALL pageToLimits(_page, _offset, _range); 
  IF _key IN ('', '0') THEN 
    SELECT NULL INTO  _key;
  END IF;
  IF _tag_id IN ('', '0') THEN 
    SELECT NULL INTO  _tag_id;
  END IF;

  IF _flag IN ('', '0') THEN 
    SELECT NULL INTO  _flag;
  END IF;

  DROP TABLE IF EXISTS _show_node;
  CREATE TEMPORARY TABLE _show_node (
    entity_id  VARCHAR(16) CHARACTER SET ascii NOT NULL,  
    hub_id VARCHAR(16)  CHARACTER SET ascii NOT NULL,
    drumate_id  VARCHAR(16)   CHARACTER SET ascii,
    contact_id  VARCHAR(16)   CHARACTER SET ascii,
    firstname  VARCHAR(255)  NULL,
    lastname   VARCHAR(255)  NULL,
    metadata   JSON  NULL,
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
    is_attachment   INT DEFAULT 0 ,
    has_mention   INT DEFAULT 0 ,
    PRIMARY KEY `entity_id`(`entity_id`)
  );

  -- P2P conversations from contact list
  INSERT INTO _show_node
  SELECT
    c.uid  entity_id, 
    _this_hub_id   hub_id,  
    c.uid  drumate_id, 
    c.id contact_id,
    IF(c.firstname='' OR c.firstname IS NULL, du.firstname, c.firstname) firstname,
    IF(c.lastname='' OR c.lastname IS NULL, du.lastname, c.lastname) lastname,
    tc.metadata,
    IF(c.surname IS NULL OR c.surname="",
      -- `du.firstname` is a VIRTUAL json_value column: it is the EMPTY STRING
      -- (not NULL) for a profile with "firstname":"" (OAuth/Apple signups with
      -- no given name, trial/invited accounts). The previous guard
      -- `IS NOT NULL OR != ""` was a tautology (always TRUE for any non-NULL),
      -- so an empty-string firstname produced display='' (blank inbox name) and
      -- the email fallback was dead code. NULLIF turns '' into NULL so COALESCE
      -- skips it and falls through to a usable name / email.
      COALESCE(NULLIF(du.firstname, ''), NULLIF(du.lastname, ''), du.email),
      COALESCE(NULLIF(TRIM(CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))), ''), du.email)
    ) as display,
    CASE WHEN IFNULL(pr.ref_ctime, 0) < IFNULL(tc.ref_ctime, 0) THEN 1 ELSE 0 END,
    tc.message,
    tc.ctime , 
    'contact',null,'active',
    CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
    CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me,
    CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END  is_archived ,
    IF(tc.attachment IS NOT NULL , 1, 0),
    0
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
  WHERE CASE WHEN _tag_id IS NOT NULL AND  _tag_id <> ''  THEN  c.id IN ( SELECT id FROM map_tag mt WHERE mt.tag_id = _tag_id) ELSE c.id =c.id END 
  AND c.uid IS NOT NULL
  AND _flag IN ('all','contact')
  AND json_value(du.profile, "$.category") != "system"
  AND CASE WHEN  ae.entity_id  IS NOT NULL THEN 'archived' ELSE 'active'  END = _option 
  AND (IFNULL(c.firstname,'') LIKE CONCAT(TRIM(IFNULL(_key,IFNULL(c.firstname,''))), '%') OR 
      IFNULL(c.lastname,'') LIKE CONCAT(TRIM(IFNULL(_key, IFNULL(c.lastname,''))), '%') OR 
      IFNULL(c.surname,'') LIKE CONCAT(TRIM(IFNULL(_key,IFNULL(c.surname,''))), '%') OR 
      IFNULL(c.source,'') LIKE CONCAT(TRIM(IFNULL(_key, IFNULL(c.source,''))), '%') );

  -- Same-domain colleagues not yet in contact list
  INSERT IGNORE INTO _show_node(entity_id, hub_id, drumate_id, firstname, lastname, display, room_count, message, ctime, flag, status, is_attachment)
  SELECT
    d.id,
    _this_hub_id,
    d.id,
    d.firstname,
    d.lastname,
    -- COALESCE alone skips only NULL, not '' — an empty-string firstname would
    -- pass through as a blank display. NULLIF maps '' to NULL so it falls back.
    COALESCE(NULLIF(d.firstname, ''), NULLIF(d.lastname, ''), d.email),
    CASE WHEN IFNULL(pr.ref_ctime, 0) < IFNULL(tc.ref_ctime, 0) THEN 1 ELSE 0 END,
    tc.message,
    tc.ctime,
    'contact',
    'active',
    IF(tc.attachment IS NOT NULL, 1, 0)
  FROM yp.drumate d
  LEFT JOIN p2p_time tc ON tc.peer_id = d.id
  LEFT JOIN p2p_read pr ON pr.peer_id = d.id AND pr.uid = _uid
  WHERE d.domain_id = _domain_id
    AND _domain_id > 1
    AND d.id != _uid
    AND d.id NOT IN (SELECT IFNULL(uid, '1') FROM contact WHERE status <> 'received')
    AND json_value(d.profile, '$.category') != 'system'
    AND _flag IN ('all', 'contact')
    AND _option = 'active'
    AND (_key IS NULL
      OR IFNULL(d.firstname, '') LIKE CONCAT(TRIM(_key), '%')
      OR IFNULL(d.lastname, '') LIKE CONCAT(TRIM(_key), '%'));

  -- P2P nocontact: peers with conversations but not in contact list
  -- du.fullname (a virtual column) already falls back to email when BOTH names
  -- are empty, but a whitespace-only name ("firstname":" ") slips past that
  -- guard and an empty-email degenerate profile leaves it blank. TRIM + NULLIF
  -- collapse those edges; the du.id tail guarantees a non-blank label.
  INSERT IGNORE INTO _show_node(entity_id,hub_id,display,flag,message,ctime,status, is_archived ,is_attachment)
  SELECT tc.peer_id ,_this_hub_id,COALESCE(NULLIF(TRIM(du.fullname), ''), NULLIF(du.email, ''), du.id),'contact',tc.message, tc.ctime,'nocontact',
  CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END,
  IF(tc.attachment IS NOT NULL , 1, 0)   
  FROM 
  p2p_time tc
  INNER JOIN yp.drumate du ON du.id = tc.peer_id
  LEFT JOIN archive_entity ae ON ae.entity_id = tc.peer_id
  WHERE  _tag_id IS NULL AND  tc.peer_id NOT IN (SELECT IFNULL(uid,'1') FROM contact) 
    AND CASE WHEN  ae.entity_id  IS NOT NULL THEN 'archived' ELSE 'active'  END = _option 
  AND tc.peer_id  NOT IN (SELECT IFNULL(entity,'1') FROM contact)
  AND _flag IN ('all','contact') AND _key IS  NULL;

  -- P2P memory: peers in contact entity (not uid) column
  -- Same whitespace/empty-email hardening as the nocontact block above.
  INSERT IGNORE INTO _show_node(entity_id,hub_id,display,flag,message,ctime,status, is_archived,is_attachment)
  SELECT tc.peer_id ,_this_hub_id,COALESCE(NULLIF(TRIM(du.fullname), ''), NULLIF(du.email, ''), du.id),'contact',tc.message, tc.ctime,'memory',
  CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END,
  IF(tc.attachment IS NOT NULL , 1, 0)   
  FROM 
  p2p_time tc
  INNER JOIN yp.drumate du ON du.id = tc.peer_id
  LEFT JOIN archive_entity ae ON ae.entity_id = tc.peer_id
  WHERE  _tag_id IS NULL AND  tc.peer_id NOT IN (SELECT IFNULL(uid,'1') FROM contact)
  AND CASE WHEN  ae.entity_id  IS NOT NULL THEN 'archived' ELSE 'active'  END = _option 
  AND tc.peer_id IN (SELECT IFNULL(entity,'1') FROM contact)
  AND _flag IN ('all','contact') AND _key IS  NULL;     


  -- Hub/group chat rooms (unchanged)
  INSERT INTO _show_node(entity_id, hub_id, display, flag, db_name, is_archived)
  SELECT 
    m.id,  m.id,
    IFNULL(h.name, user_filename)  group_name, 
    'share',
    db_name,
    CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END        
  FROM 
  media m
  LEFT JOIN archive_entity ae ON ae.entity_id = m.id
  INNER JOIN yp.hub h on  h.id = m.id 
  INNER  JOIN yp.entity he ON m.id = he.id AND he.area <> 'share'
  WHERE category = 'hub'
  AND he.area = 'private'
  AND CASE WHEN  ae.entity_id  IS NOT NULL THEN 'archived' ELSE 'active'  END = _option 
  AND CASE WHEN _tag_id IS NOT NULL AND  _tag_id <> ''  THEN  m.id IN ( SELECT id FROM map_tag mt WHERE mt.tag_id = _tag_id) ELSE m.id =m.id END
  AND _flag IN ('all','share')
  AND ( IFNULL(h.name, user_filename) LIKE CONCAT(TRIM(IFNULL(_key,IFNULL(h.name, user_filename) )), '%') ); 

  ALTER TABLE _show_node ADD `is_checked` boolean default 0 ;
  UPDATE   _show_node SET is_checked = 1 WHERE flag='contact';
    
  SELECT entity_id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
  WHILE _nid IS NOT NULL DO

    SET @st = CONCAT('CALL ', _db_name ,'.room_detail(?,?)');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING  JSON_OBJECT('uid',_this_hub_id ) , _temp_result ;
    DEALLOCATE PREPARE stamt; 
  
    SELECT JSON_VALUE(_temp_result, "$.read_cnt") INTO _read_cnt;
    SELECT JSON_VALUE(_temp_result, "$.message") INTO _message;
    SELECT JSON_VALUE(_temp_result, "$.ctime") INTO _ctime;
    SELECT JSON_VALUE(_temp_result, "$.attachment") INTO _attachment;
    SELECT JSON_VALUE(_temp_result, "$.metadata") INTO _metadata;
    SELECT IFNULL(JSON_VALUE(_temp_result, "$.has_mention"), 0) INTO _has_mention;

    UPDATE _show_node SET
      room_count = _read_cnt,
      `message` = _message,
      ctime = _ctime,
      is_attachment = IF(_attachment IS NOT NULL, 1, 0),
      has_mention = _has_mention
    WHERE entity_id = _nid;

    UPDATE _show_node SET is_checked = 1 WHERE entity_id = _nid;
    SELECT NULL, NULL, NULL, NULL, 0 INTO _read_cnt, _message, _ctime, _nid, _has_mention;
    SELECT entity_id ,db_name FROM _show_node WHERE is_checked =0  LIMIT 1 INTO _nid, _db_name; 
  END WHILE;


  SELECT  _page as `page`,
    entity_id,
    hub_id,
    drumate_id,
    contact_id,
    firstname,
    lastname,
    display,
    room_count,
    yp.online_state(drumate_id) `online`,
    message,
    metadata,
    ctime,
    flag,
    status,
    is_blocked,
    is_blocked_me, 
    is_archived ,
    is_attachment,
    has_mention
  FROM _show_node
  ORDER BY IFNULL(ctime,0) DESC, entity_id ASC
  LIMIT _offset, _range;

  DROP TABLE IF EXISTS _show_node;
END $
DELIMITER ;