DELIMITER $
DROP PROCEDURE IF EXISTS `contact_search_by_domain_next`$
CREATE PROCEDURE `contact_search_by_domain_next`(
  IN _key VARCHAR(100),
  IN _page TINYINT(11)
)
BEGIN
  DECLARE _range INT(6);
  DECLARE _offset INT(6);
  DECLARE _uid VARCHAR(16);
  DECLARE _domain_id INTEGER;
  DECLARE _domain VARCHAR(512);
  DECLARE _mail VARCHAR(500);
  
  -- Get current user info including domain_id
  SELECT d.domain, e.id, e.dom_id, d.email
  FROM yp.entity e
  INNER JOIN yp.drumate d USING(id)
  WHERE d.db_name = DATABASE()
  INTO _domain, _uid, _domain_id, _mail;
  
  CALL pageToLimits(_page, _offset, _range);
  
  SELECT * FROM (
    -- 1. Search in contacts
    SELECT 
      _page AS `page`,
      1 AS is_mycontact,
      'my_contact' AS type,
      c.id AS id,
      IF(COALESCE(c.firstname, c.lastname) IS NULL, 
        IFNULL(ce.email, de.email), 
        NULL
      ) AS email,
      IFNULL(c.surname, IF(COALESCE(c.firstname, c.lastname) IS NULL, 
        IFNULL(ce.email, de.email), 
        CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))
      )) AS surname,
      c.surname AS given_surname,
      c.firstname,
      c.lastname,
      CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')) AS fullname,
      CASE WHEN c.uid IS NULL THEN 0 ELSE 1 END AS is_drumate,
      NULL AS ident,
      NULL AS username,
      1 AS is_need_email,
      c.status,
      CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END AS is_blocked,
      CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END AS is_blocked_me
    FROM contact c
      LEFT JOIN contact_email ce ON ce.contact_id = c.id AND ce.is_default = 1
      LEFT JOIN yp.entity e ON e.id = c.uid
      LEFT JOIN yp.drumate de ON de.id = c.entity
      LEFT JOIN yp.drumate du ON du.id = c.uid
      LEFT JOIN yp.contact_block mycb ON c.id = mycb.contact_id
      LEFT JOIN yp.drumate dm ON dm.email = ce.email
      LEFT JOIN yp.contact_block hiscb 
        ON (hiscb.owner_id = c.entity OR hiscb.owner_id = dm.id)
        AND (hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail)
    WHERE 
      (c.firstname LIKE CONCAT(TRIM(_key), '%') 
        OR c.lastname LIKE CONCAT(TRIM(_key), '%')
        OR c.surname LIKE CONCAT(TRIM(_key), '%')
        OR COALESCE(c.firstname, c.lastname, c.source) LIKE CONCAT(TRIM(_key), '%')
      )
      AND c.status <> 'received'
    
    UNION ALL
    
    -- 2. Search in same domain drumates (Paid plan only)
    SELECT 
      _page AS `page`,
      1 AS is_mycontact,
      'colleague' AS type,
      d.id AS id,
      CASE WHEN d.email LIKE CONCAT(TRIM(_key), '%') THEN d.email ELSE NULL END AS email,
      d.fullname AS surname,
      NULL AS given_surname,
      d.firstname,
      d.lastname,
      d.fullname AS fullname,
      1 AS is_drumate,
      CASE WHEN e.ident LIKE CONCAT(TRIM(_key), '%') THEN e.ident ELSE NULL END AS ident,
      d.username,
      0 AS is_need_email,
      'mate' AS status,
      CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END AS is_blocked,
      CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END AS is_blocked_me
    FROM yp.drumate d 
      INNER JOIN yp.entity e USING(id)
      LEFT JOIN yp.contact_block mycb 
        ON mycb.owner_id = _uid 
        AND (mycb.uid = d.id OR mycb.entity = d.id OR mycb.entity = d.email)
      LEFT JOIN yp.contact_block hiscb 
        ON hiscb.owner_id = d.id
        AND (hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail)
    WHERE
      d.domain_id = _domain_id
      AND _domain_id > 1
      AND d.id != _uid
      AND d.id NOT IN (SELECT entity FROM contact WHERE status <> 'received')
      AND (
        d.firstname LIKE CONCAT(TRIM(_key), '%')
        OR d.lastname LIKE CONCAT(TRIM(_key), '%')
        OR d.fullname LIKE CONCAT(TRIM(_key), '%')
        OR d.email LIKE CONCAT(TRIM(_key), '%')
        OR e.ident LIKE CONCAT(TRIM(_key), '%')
      )
  ) AS combined_results
  ORDER BY fullname ASC
  LIMIT _offset, _range;
END$
DELIMITER ;