DELIMITER $

DROP PROCEDURE IF EXISTS `folder_save_permissions`$
CREATE PROCEDURE `folder_save_permissions`(
  IN _nid    VARCHAR(16) CHARACTER SET ascii,
  IN _config TEXT
)
BEGIN
  -- Persists the admin Permission popup's config blob into the folder's
  -- media.metadata at key 'fperm'. The shape is owned by the FE — see
  -- folder_get_permissions for the keys consumed back. We use
  -- JSON_MERGE_PATCH so any pre-existing keys outside 'fperm' (md5Hash,
  -- captions, etc.) survive untouched.
  --
  -- _config arrives as a JSON string from the JS layer.
  --
  -- Member list and OTL state are NOT touched here — they have their own
  -- handlers (member_grant_folder_access, folder_generate_otl, etc.).

  DECLARE _patch TEXT;

  SET _patch = CONCAT('{"fperm":', _config, '}');

  UPDATE media
  SET metadata = JSON_MERGE_PATCH(IFNULL(metadata, '{}'), _patch),
      mtime    = UNIX_TIMESTAMP()
  WHERE id = _nid;

  SELECT 'OK' AS status, _nid AS nid;
END$

DELIMITER ;
