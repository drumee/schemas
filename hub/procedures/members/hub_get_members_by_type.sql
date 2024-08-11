DELIMITER $

DROP PROCEDURE IF EXISTS `hub_get_members_by_type`$
CREATE PROCEDURE `hub_get_members_by_type`(
  IN _uid  VARCHAR(16),
  IN _member_type enum('all', 'owner', 'not_owner', 'admin', 'other'),
  IN _page INT(6) 
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _drumate_db VARCHAR(400);
    CALL pageToLimits(_page, _offset, _range);

    SELECT db_name  FROM yp.entity WHERE id = _uid INTO _drumate_db;

    DROP TABLE IF EXISTS _contact;
    CREATE TEMPORARY TABLE _contact AS
    SELECT  
      _page as `page`, 
      d.id,
      permission AS privilege,
      d.email,
      d.firstname  firstname,
      d.lastname  lastname,
      d.fullname  fullname,
      d.fullname  surname ,
      -- TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
      -- TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname
      JSON_VALUE(d.profile, "$.connected") `online`
    FROM permission p 
    INNER JOIN yp.drumate d on p.entity_id=d.id 
    LEFT JOIN yp.socket s on s.uid=d.id
    WHERE 
      resource_id='*'  AND 
      CASE 
        WHEN _member_type ='owner' THEN permission&32 > 0 
        WHEN _member_type ='admin' THEN permission&16 > 0 
        WHEN _member_type ='not_owner' THEN permission&32 = 0 
        WHEN _member_type ='other' THEN permission&16 = 0 
        ELSE 1
      END = 1;

     -- ALTER TABLE _contact ADD surname  varchar(255);
       ALTER TABLE _contact ADD contact_id  varchar(16);
       ALTER TABLE _contact ADD status  varchar(16);



    SET @st = CONCAT(" UPDATE ",_drumate_db, ".contact c
      INNER JOIN ",_drumate_db, ".contact_email ce ON ce.contact_id = c.id   AND ce.is_default = 1  
      INNER JOIN _contact tc ON tc.id = c.uid OR tc.id = c.entity OR tc.email = ce.email
      SET tc.contact_id  = c.id, 
          tc.status = c.status,
          tc.firstname = c.firstname,  
          tc.lastname  = c.lastname,
          tc.surname   = IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,ce.email,CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,
          tc.fullname  = CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, '')) 
        "); 
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT page,id,privilege,email,lastname,fullname,surname, `online`,firstname, 1 as is_drumate, status, contact_id
    -- Temp fix - shall be updated upon ui pushed into production
    -- IF(firstname IS NULL AND lastname IS NULL, email, fullname) firstname 
    FROM _contact
    GROUP BY email
    ORDER BY firstname ASC, id ASC; -- LIMIT _offset, _range;  

END$

DELIMITER ;
