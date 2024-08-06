DELIMITER $


-- =========================================================
-- Checks whether drumate with given id/email exist or not.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_create_share_box`$
CREATE PROCEDURE `drumate_create_share_box`(
  IN _id          VARCHAR(16),
  IN _owner_id    VARCHAR(16),
  IN _root_id     VARCHAR(16)
)
BEGIN
  REPLACE INTO share_box values(null, _id, _owner_id, _root_id);
  UPDATE entity set settings=JSON_SET(settings, "$.default_privilege", 7) where id=_id;
END$


DELIMITER ;
