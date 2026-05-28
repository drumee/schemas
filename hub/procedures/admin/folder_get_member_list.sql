DELIMITER $

DROP PROCEDURE IF EXISTS `folder_get_member_list`$
CREATE PROCEDURE `folder_get_member_list`(
  IN _nid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- Returns every drumate with an active permission row on this folder.
  -- Used by the admin Permission popup's "Members access" section so it
  -- can show real names + emails + per-folder roles instead of the
  -- hardcoded SAMPLE_MEMBERS array.
  --
  -- Companion to folder_get_permissions; split into a separate SP to
  -- keep each CALL single-resultset (the @drumee mariadb wrapper drops
  -- chunks beyond the first).

  SELECT
    p.entity_id      AS uid,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    p.permission     AS permission,
    CASE
      WHEN p.permission & 16 THEN 'Admin'
      WHEN p.permission & 8  THEN 'Edit'
      WHEN p.permission & 4  THEN 'Chat'
      ELSE                        'View'
    END              AS role,
    p.expiry_time    AS expiry_time
  FROM permission p
  INNER JOIN yp.drumate d ON d.id = p.entity_id
  WHERE p.resource_id = _nid
    AND p.permission  > 0
    AND (p.expiry_time = 0 OR p.expiry_time > UNIX_TIMESTAMP())
  ORDER BY d.lastname, d.firstname;
END$

DELIMITER ;
