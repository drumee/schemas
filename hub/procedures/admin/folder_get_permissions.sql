DELIMITER $

DROP PROCEDURE IF EXISTS `folder_get_permissions`$
CREATE PROCEDURE `folder_get_permissions`(
  IN _nid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- Returns the persisted permission config blob for one folder. The
  -- popup's member list is fetched separately via folder_get_member_list
  -- so this SP can stay single-resultset (the @drumee mariadb wrapper
  -- collapses multi-resultset CALLs to one chunk and discards the rest).
  --
  -- Config is stored in media.metadata at key 'fperm' by
  -- folder_save_permissions. Falls back to defaults derived from the
  -- workspace's area when the folder has no saved config yet.

  DECLARE _hub_area VARCHAR(30);

  SELECT e.area
  FROM yp.entity e
  WHERE e.db_name = DATABASE()
  INTO _hub_area;

  SELECT
    COALESCE(JSON_VALUE(m.metadata, '$.fperm.mode'),
             IF(_hub_area = 'share', 'shared', 'restricted')) AS mode,
    COALESCE(CAST(JSON_VALUE(m.metadata, '$.fperm.access.view') AS UNSIGNED), 1) AS access_view,
    COALESCE(CAST(JSON_VALUE(m.metadata, '$.fperm.access.edit') AS UNSIGNED), 0) AS access_edit,
    COALESCE(CAST(JSON_VALUE(m.metadata, '$.fperm.access.chat') AS UNSIGNED), 1) AS access_chat,
    COALESCE(CAST(JSON_VALUE(m.metadata, '$.fperm.auto_revoke') AS UNSIGNED), 0) AS auto_revoke,
    COALESCE(CAST(JSON_VALUE(m.metadata, '$.fperm.auto_revoke_minutes') AS UNSIGNED), 30) AS auto_revoke_minutes,
    COALESCE(CAST(JSON_VALUE(m.metadata, '$.fperm.one_time') AS UNSIGNED), 0) AS one_time,
    JSON_VALUE(m.metadata, '$.fperm.one_time_url') AS one_time_url
  FROM media m
  WHERE m.id = _nid;
END$

DELIMITER ;
