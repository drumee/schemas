DELIMITER $

-- =========================================================
-- department_grant_save
-- =========================================================
-- Record (or update) a department grant. prev_privilege is written on the
-- FIRST record only: it is what the person had before any department raised
-- them, and a later re-grant at another level must not overwrite it.
DROP PROCEDURE IF EXISTS `department_grant_save`$
CREATE PROCEDURE `department_grant_save`(
  IN _domain_id INT UNSIGNED, IN _hub_id VARCHAR(16), IN _uid VARCHAR(16),
  IN _privilege TINYINT UNSIGNED, IN _prev TINYINT UNSIGNED
)
BEGIN
  INSERT INTO department_grant (domain_id, hub_id, uid, privilege, prev_privilege, mtime)
    VALUES (_domain_id, _hub_id, _uid, _privilege, _prev, UNIX_TIMESTAMP())
    ON DUPLICATE KEY UPDATE privilege = VALUES(privilege), mtime = VALUES(mtime);
  SELECT _hub_id AS hub_id, _uid AS uid;
END$

DELIMITER ;
