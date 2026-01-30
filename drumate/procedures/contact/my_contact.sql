DELIMITER $


-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `my_contact`$
CREATE PROCEDURE `my_contact`(
  IN _key          VARCHAR(100),
  IN _page         TINYINT(11),
  IN _filter_email  JSON,
  IN _status      VARCHAR(100)
)
BEGIN
  DECLARE _domain_id INTEGER;
  DECLARE _range INTEGER;
  DECLARE _offset INTEGER;
  DECLARE _uid VARCHAR(16);
  DECLARE _domain VARCHAR(512);
  DECLARE _mail  VARCHAR(500);
  DECLARE _length INTEGER DEFAULT 0;
  DECLARE _idx INTEGER DEFAULT 0;
  
  IF _status IN ('') THEN 
     SELECT NULL INTO  _status;
  END IF;

  SELECT JSON_LENGTH(_filter_email)  INTO _length;
  SELECT e.dom_id, d.id, email FROM yp.entity e INNER JOIN yp.drumate d USING(id)
    WHERE db_name=database() INTO _domain_id, _uid, _mail;

  DROP TABLE IF EXISTS  _temp_mail;
  CREATE TEMPORARY TABLE `_temp_mail` (  `email` varchar(5000) NOT NULL); 
  
  WHILE _idx < _length  DO 
     INSERT INTO _temp_mail SELECT JSON_UNQUOTE(JSON_EXTRACT(_filter_email, CONCAT("$[", _idx, "]")));
     SELECT _idx + 1 INTO _idx;
  END WHILE;

  CALL pageToLimits(_page, _offset, _range);

  SELECT 
    _page as `page`,
    1 as is_mycontact,
    coalesce( du.id,de.id, c.entity) as id,
    coalesce (du.email,de.email,ce.email) email,
    c.firstname,
    c.lastname,
    CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')) fullname,
    IFNULL(c.surname, IF(COALESCE(c.firstname, c.lastname) IS NULL, 
      IFNULL(ce.email, de.email), 
      CONCAT(IFNULL(c.firstname, ''),' ', IFNULL(c.lastname, '')))
    ) AS surname,
    CASE WHEN c.uid IS NULL THEN 0 ELSE 1 END   is_drumate ,
    CASE WHEN du.id IS NULL THEN 1 ELSE 0 END is_need_email,
    c.status,
    CASE WHEN mycb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked,
    CASE WHEN hiscb.sys_id IS NOT NULL THEN 1 ELSE 0 END is_blocked_me 
    FROM contact c
    LEFT JOIN contact_email ce on ce.contact_id = c.id AND ce.is_default = 1
    LEFT JOIN yp.drumate de ON de.id = c.entity
    LEFT JOIN yp.drumate du ON du.id = c.uid
    LEFT JOIN yp.contact_block mycb ON c.id = mycb.contact_id
    LEFT JOIN yp.drumate dm ON dm.email = ce.email
    LEFT JOIN yp.contact_block hiscb ON (hiscb.owner_id =  c.entity OR hiscb.owner_id = dm.id) 
            AND( hiscb.uid = _uid OR hiscb.entity = _uid OR hiscb.entity = _mail ) 
    WHERE 
      (c.firstname LIKE CONCAT(TRIM(_key), '%') OR 
        c.lastname LIKE CONCAT(TRIM(_key), '%') OR 
        c.surname LIKE CONCAT(TRIM(_key), '%') OR 
        c.source LIKE CONCAT(TRIM(_key), '%') ) AND c.status <> 'received'
        AND  _status = CASE WHEN c.status = 'active' THEN 'active' ELSE 'paper' END 
        AND COALESCE(du.email, de.email, ce.email) NOT IN (SELECT email FROM _temp_mail)
  UNION
  SELECT 
    _page as `page`,
    1 as is_mycontact,
    d.id id,
    d.email email,
    d.firstname,
    d.lastname,
    d.fullname,
    COALESCE(d.firstname, d.lastname, d.email) surname,
    1 is_drumate ,
    0 is_need_email,
    'mate' status,
    0 is_blocked,
    0 is_blocked_me 
    FROM yp.drumate d WHERE domain_id = _domain_id AND _domain_id>1 AND id!=_uid

  ORDER BY surname ASC LIMIT _offset, _range;
END$

DELIMITER ;
