DELIMITER $
DROP PROCEDURE IF EXISTS `lookup_hubers`$
CREATE PROCEDURE `lookup_hubers`(
  IN _name   VARCHAR(255),
  IN _page         INT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);

  CALL pageToLimits(_page, _offset, _range);

  SELECT 
    _page as `page`,
    d.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    permission.ctime, 
    permission.utime, 
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl
    FROM permission LEFT JOIN yp.drumate d ON entity_id=d.id 
    WHERE d.id IS NOT NULL AND (
      firstname LIKE CONCAT("%", _name, "%") OR       
      lastname LIKE CONCAT("%", _name, "%") OR       
      mobile LIKE CONCAT("%", _name, "%") OR      
      email LIKE CONCAT("%", _name, "%")       
    )
    ORDER BY firstname ASC LIMIT _offset, _range;
END $
DELIMITER ;
