DELIMITER $
DROP PROCEDURE IF EXISTS `dmz_get_meeting_members`$
CREATE PROCEDURE `dmz_get_meeting_members`(
 IN _uid  VARCHAR(16),
 IN _nid   VARCHAR(16)
)
BEGIN
  DECLARE _drumate_db VARCHAR(400);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);

    SELECT db_name  FROM yp.entity WHERE id = _uid INTO _drumate_db;

    DROP TABLE IF EXISTS _contact;
    CREATE TEMPORARY TABLE _contact AS
    SELECT
      u.id  guest_id,
      d.id  drumate_id,
      u.email,
      u.email surname,
      CASE WHEN d.id IS NULL THEN 0 ELSE 1 END  is_drumate
    FROM
      permission p
      INNER JOIN yp.dmz_user u ON p.entity_id = u.id
      LEFT JOIN  yp.drumate d ON d.email = u.email
    WHERE u.id <> yp.get_sysconf('guest_id') AND
      p.resource_id = _nid;


    ALTER TABLE _contact ADD contact_id  varchar(16);

    ALTER TABLE _contact ADD fullname  varchar(255);
    ALTER TABLE _contact ADD lastname  varchar(255);
    ALTER TABLE _contact ADD firstname  varchar(255);
    ALTER TABLE _contact ADD status  varchar(16);


    SET @st = CONCAT(
      "UPDATE ", _drumate_db, 
      ".contact c INNER JOIN ",_drumate_db, 
      ".contact_email ce ON ce.contact_id=c.id AND ce.is_default=1 ", 
      "INNER JOIN _contact tc ON tc.drumate_id=c.uid OR tc.email=ce.email ",
      "SET tc.contact_id  = c.id,
          tc.status = c.status,
          tc.firstname = c.firstname,
          tc.lastname  = c.lastname,
          tc.surname   = IFNULL(c.surname,IF(coalesce(c.firstname, c.lastname) IS NULL,ce.email,CONCAT( IFNULL(c.firstname, '') ,' ',  IFNULL(c.lastname, '')))) ,
          tc.fullname  = CONCAT(IFNULL(c.firstname, ''), ' ', IFNULL(c.lastname, ''))
        "
    );
    PREPARE stmt FROM @st;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

  SELECT * FROM _contact;
END$  

DELIMITER ;