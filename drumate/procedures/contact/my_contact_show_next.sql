DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_show_next`$
CREATE PROCEDURE `my_contact_show_next`(
  IN _tag_id  VARCHAR(16) CHARACTER SET ascii, 
  IN _sort_by VARCHAR(20),
  IN _order   VARCHAR(20),
  IN _option VARCHAR(20),
  IN _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _lvl INT(4);
  DECLARE _online INT(4) DEFAULT 0;
  DECLARE _uid  VARCHAR(16) CHARACTER SET ascii;
  DECLARE _mail  VARCHAR(500);
  DECLARE _domain_id INTEGER;
  
  CALL pageToLimits(_page, _offset, _range); 

  -- Get current user info including domain_id
  SELECT e.id, d.email, e.dom_id 
  FROM yp.entity e 
    INNER JOIN yp.drumate d USING(id)
    WHERE e.db_name = DATABASE() 
    INTO _uid, _mail, _domain_id;

  -- Build tag hierarchy
  DROP TABLE IF EXISTS _tag;
  CREATE TEMPORARY TABLE _tag(
    `tag_id` varchar(16) CHARACTER SET ascii NOT NULL,
    `is_checked` boolean default 0
  );

  DROP TABLE IF EXISTS _map_tag;
  CREATE TEMPORARY TABLE _map_tag(
    `tag_id` varchar(16) CHARACTER SET ascii  NOT NULL,
    `id`     varchar(16) CHARACTER SET ascii NOT NULL
  );

  -- Process tag hierarchy
  IF _tag_id IS NULL OR (ltrim(_tag_id) = '') THEN
    INSERT INTO _tag (tag_id) SELECT tag_id FROM tag; 
  ELSE 
    INSERT INTO _tag (tag_id) SELECT _tag_id;
    WHILE (IFNULL((SELECT 1 FROM _tag WHERE is_checked = 0 LIMIT 1), 0) = 1) AND IFNULL(_lvl, 0) < 1000 DO
      SELECT tag_id FROM _tag WHERE is_checked = 0 LIMIT 1 INTO _tag_id;
      INSERT INTO _tag (tag_id) SELECT tag_id FROM tag WHERE parent_tag_id = _tag_id;
      UPDATE _tag SET is_checked = 1 WHERE tag_id = _tag_id; 
      SELECT IFNULL(_lvl, 0) + 1 INTO _lvl;
    END WHILE; 
  END IF;

  INSERT INTO _map_tag (tag_id, id) 
  SELECT tag_id, id FROM map_tag WHERE tag_id IN (SELECT tag_id FROM _tag); 

  SELECT * FROM (
    -- 1. Contacts from contact table
    SELECT 
      _page as `page`, 
      c.id, 
      1 as is_mycontact, 
      'my_contact' as type,
      c.firstname,
      c.lastname, 
      coalesce(ce.email, de.email, IF(c.entity LIKE '%@%', c.entity, NULL)) email,
      IF(_domain_id > 1 AND coalesce(de.domain_id, du.domain_id) = _domain_id, 1, 0) is_same_domain,
      c.comment,
      c.ctime,
      c.entity entity,
      IFNULL(c.surname, IF(coalesce(c.firstname, c.lastname) IS NULL, 
        IFNULL(ce.email, de.email), 
        CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')))) as surname,
      c.surname given_surname,
      IF(socket.uid IS NULL, 0, du.connected) online,
      CASE WHEN yp.user_exists(c.entity) = 1 THEN 1 ELSE 0 END is_drumate,
      du.username ident, 
      du.username,
      c.status,
      1 is_need_email,
      CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
      CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me,
      CASE WHEN ae.entity_id IS NOT NULL THEN 1 ELSE 0 END is_archived
    FROM contact c
      LEFT JOIN contact_email ce ON ce.contact_id = c.id AND ce.is_default = 1  
      LEFT JOIN yp.drumate de ON de.id = c.entity
      LEFT JOIN yp.drumate du ON du.id = c.uid 
      LEFT JOIN (SELECT distinct uid FROM yp.socket WHERE state = 'active') socket ON socket.uid = c.entity
      LEFT JOIN yp.entity e ON e.id = c.uid 
      LEFT JOIN yp.contact_block mycb ON c.id = mycb.contact_id
      LEFT JOIN yp.drumate dm ON dm.email = ce.email
      LEFT JOIN yp.contact_block hiscb ON (hiscb.owner_id = c.entity OR hiscb.owner_id = dm.id) 
        AND (hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail) 
      LEFT JOIN archive_entity ae ON ae.entity_id = c.id
    WHERE 
      CASE WHEN _tag_id IS NOT NULL AND _tag_id <> '' THEN c.id IN (SELECT id FROM _map_tag) ELSE c.id = c.id END 
      AND c.status <> 'received' 
      AND CASE WHEN _option = 'sent' THEN c.status
          ELSE (CASE WHEN entity_id IS NOT NULL THEN 'archived' ELSE 'active' END) END = _option

    UNION ALL

    -- 2. Colleagues from yp.drumate (only for paid plans)
    SELECT 
      _page as `page`, 
      d.id, 
      1 as is_mycontact, 
      'my_contact' as type,
      d.firstname,
      d.lastname, 
      d.email,
      1 is_same_domain,
      NULL as comment,
      NULL as ctime,
      d.id as entity,
      COALESCE(d.firstname, d.lastname, d.email) as surname,
      NULL as given_surname,
      IF(socket.uid IS NULL, 0, d.connected) online,
      1 as is_drumate,
      d.username as ident, 
      d.username,
      _option as status,
      0 as is_need_email,
      0 as is_blocked,
      0 as is_blocked_me,
      0 as is_archived
    FROM yp.drumate d
      LEFT JOIN (SELECT distinct uid FROM yp.socket WHERE state = 'active') socket ON socket.uid = d.id
    WHERE 
      d.domain_id = _domain_id 
      AND _domain_id > 1  -- Only for paid plans
      AND d.id != _uid    -- Exclude self
      -- Duplicate prevention: Exclude colleagues already in contact table (except 'received' status)
      AND d.id NOT IN (SELECT entity FROM contact WHERE status <> 'received')
      -- UNION only when no tag filter (drumates don't have tags)
      AND (_tag_id IS NULL OR _tag_id = '')
      -- UNION only when option is 'active' (drumates can't be 'sent' or 'archived')
      AND _option = 'active'
  ) combined_contacts
  
  ORDER BY 
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'asc' THEN ctime END ASC,
    CASE WHEN LCASE(_sort_by) = 'date' and LCASE(_order) = 'desc' THEN ctime END DESC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'asc' THEN surname END ASC,
    CASE WHEN LCASE(_sort_by) = 'name' and LCASE(_order) = 'desc' THEN surname END DESC,
    id ASC
  LIMIT _offset, _range;

END$

DELIMITER ;