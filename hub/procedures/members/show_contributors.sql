DELIMITER $
DROP PROCEDURE IF EXISTS `show_contributors`$
CREATE PROCEDURE `show_contributors`(
  IN _page         INT(4)
)
BEGIN
  DECLARE _range int(6);
  DECLARE _offset int(6);
  DECLARE _count int(6);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _p int(4);

  CALL pageToLimits(_page, _offset, _range);
  SELECT COUNT(*) FROM member INTO _count;
  SELECT id FROM yp.entity WHERE db_name = database() INTO _hub_id;

  SELECT 
    _page as `page`,
    drumate.id, 
    permission AS privilege,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.firstname')), ''))AS firstname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.lastname')), '')) AS lastname,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.mobile')), '')) AS mobile,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.address')), '')) AS address,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.city')), ''))) AS city,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.content')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country.value')), IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.country')), ''))) AS country_code,
    expiry_time AS expiry,
    permission.ctime, 
    permission.utime, 
    _count as total
    FROM permission LEFT JOIN yp.drumate ON entity_id=drumate.id 
    WHERE entity_id != _hub_id ORDER BY permission DESC LIMIT _offset, _range;
END $
DELIMITER ;
