
DELIMITER $

DROP PROCEDURE IF EXISTS `acl_show_users`$
CREATE PROCEDURE `acl_show_users`(
  IN _resouce_id VARCHAR(16)
)
BEGIN
  DECLARE _node_permission VARCHAR(16);
  DECLARE _level VARCHAR(16);

  SELECT permission_tree(_resouce_id) INTO _node_permission;
  SELECT 
    CASE 
      WHEN _node_permission = '*' THEN 'hub'
      WHEN _node_permission = _resouce_id THEN 'node'
      ELSE 'parent'
    END
  INTO _level;

  SELECT 
    entity_id AS uid, 
    firstname,
    lastname,
    _level AS level,
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default')) AS avatar,
    permission AS privilege
  FROM permission INNER JOIN (yp.drumate) ON drumate.id=entity_id 
  WHERE resource_id = _node_permission

  UNION

  SELECT 
    entity_id AS uid, 
    firstname,
    lastname,
    'hub' AS level,
    IF(expiry_time > 0, expiry_time - UNIX_TIMESTAMP(), 0) AS ttl,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.email')), '')) AS email,
    TRIM(IFNULL(JSON_UNQUOTE(JSON_EXTRACT(profile, '$.avatar')), 'default')) AS avatar,
    permission AS privilege
  FROM permission INNER JOIN (yp.drumate) ON drumate.id=entity_id 
  WHERE resource_id = '*';

END $
DELIMITER ;

