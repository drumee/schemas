DELIMITER $

-- =========================================================
--
-- NON_DRUMATES
--
-- =========================================================

-- =========================================================
-- Adds non drumate email and its access information.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_add_non_drumate`$
CREATE PROCEDURE `yp_add_non_drumate`(
  IN _email         VARCHAR(500),
  IN _firstname     VARCHAR(200),
  IN _lastname      VARCHAR(200),
  IN _mobile        VARCHAR(40),
  IN _extra         MEDIUMTEXT,
  IN _privilege     VARCHAR(50),
  IN _action        VARCHAR(50),
  IN _entity_id     VARCHAR(100),
  IN _item_id       VARCHAR(100),
  IN _expiry_time   INT(11)
)
BEGIN
  DECLARE _id   VARBINARY(16) DEFAULT '';
  DECLARE duplicate_key CONDITION FOR 1062;
  DECLARE _ts INT(11) DEFAULT 0;
  DECLARE _last INT(11) DEFAULT 0;
  DECLARE _token VARCHAR(255);
  DECLARE EXIT HANDLER FOR duplicate_key
  BEGIN
    SELECT sys_id FROM non_drumate WHERE email = _email AND `action` = _action
      AND entity_id = _entity_id AND item_id = _item_id INTO _id;
    UPDATE non_drumate SET firstname = _firstname, lastname = _lastname, mobile = _mobile,
      extra = IF(IFNULL(_extra, "") = "", "{}", _extra),
      privilege = _privilege, token = _token, expiry_time = IF(IFNULL(_expiry_time, 0) = 0, 0,
      UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))), ctime = _ts
      WHERE sys_id = _id;
    SELECT * FROM non_drumate WHERE id = _id;
  END;
  SELECT yp.uniqueId() INTO _id;
  SELECT UNIX_TIMESTAMP() INTO _ts;
  SELECT SHA1(UUID()) INTO _token;
  INSERT INTO non_drumate VALUES (NULL, _id, _email, _firstname, _lastname,
    _mobile, IF(IFNULL(_extra, "") = "", "{}", _extra),
    _privilege, _token, _action, _entity_id, _item_id, IF(IFNULL(_expiry_time, 0) = 0, 0,
    UNIX_TIMESTAMP(TIMESTAMPADD(HOUR,_expiry_time, FROM_UNIXTIME(_ts)))), _ts);
  SELECT LAST_INSERT_ID() INTO _last;
  SELECT * FROM non_drumate WHERE sys_id = _last;
END$

-- =========================================================
-- Removes non drumate email and its access information.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_remove_non_drumate`$
CREATE PROCEDURE `yp_remove_non_drumate`(
  IN _id          VARCHAR(200),
  IN _action      VARCHAR(50),
  IN _entity_id   VARCHAR(100),
  IN _item_id     VARCHAR(100)
)
BEGIN
  DELETE FROM non_drumate WHERE (id = _id OR email = _id) AND `action` = _action
    AND entity_id = _entity_id AND item_id = _item_id;
END$

-- =========================================================
-- Deletes all expired non-drumate access.
-- =========================================================
DROP PROCEDURE IF EXISTS `yp_delete_expired_non_drumate`$
CREATE PROCEDURE `yp_delete_expired_non_drumate`()
BEGIN
  DELETE FROM non_drumate WHERE (expiry_time <> 0 AND expiry_time < UNIX_TIMESTAMP());
END$

DELIMITER ;