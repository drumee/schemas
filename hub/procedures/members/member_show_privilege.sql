DELIMITER $
DROP PROCEDURE IF EXISTS `member_show_privilege`$
CREATE PROCEDURE `member_show_privilege`(
  _uid VARCHAR(16)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);


  SELECT drumate.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    permission.ctime, 
    permission.utime, 
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    _count as total
    FROM permission LEFT JOIN yp.drumate ON entity_id=drumate.id 
    WHERE entity_id = _uid and resource_id='*';
END $
DELIMITER ;
