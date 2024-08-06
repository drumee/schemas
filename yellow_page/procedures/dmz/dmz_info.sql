DELIMITER $
--  DROP PROCEDURE IF EXISTS `dmz_info`$
DROP PROCEDURE IF EXISTS `dmz_info_next`$
CREATE PROCEDURE `dmz_info_next`(
  IN _token     VARCHAR(64)
)
BEGIN
  -- DECLARE _id  VARCHAR(16) ; 

  DECLARE _db_name VARCHAR(50); 
  DECLARE _uid VARCHAR(50) CHARACTER SET ascii; 
  DECLARE _nid VARCHAR(50) CHARACTER SET ascii; 
  DECLARE _owner_id VARCHAR(50); 
  DECLARE _fullname VARCHAR(150); 
  DECLARE _is_user INT DEFAULT 0 ;
  
  SELECT db_name FROM entity 
    WHERE id IN (SELECT hub_id FROM dmz_token t WHERE t.id = _token) 
    INTO _db_name;

  SELECT owner_id FROM yp.hub
    INNER JOIN entity USING(id)
    WHERE db_name=_db_name
    INTO _owner_id;

  IF _db_name IS NULL THEN 
    SELECT 1 failed, 'TICKET_INVALID' validity;
  ELSE 
    SELECT CONCAT(firstname, ' ', IFNULL(lastname, '')) FROM drumate
      WHERE id = _owner_id
      INTO _fullname;
    
    SELECT node_id, guest_id FROM dmz_token t
      WHERE t.id = _token
      INTO _nid, _uid;

    SELECT 0 INTO _is_user; 
    SELECT 1 FROM dmz_user 
      WHERE id = _uid
      INTO _is_user;

    SET @s = CONCAT("SELECT ", _db_name,".user_permission(?,?) INTO @p");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt;
    
    SET @s = CONCAT("SELECT ", _db_name,".user_expiry(?,?) INTO @e");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _uid, _nid;
    DEALLOCATE PREPARE stmt;


    SET @s = CONCAT("SELECT id FROM ", _db_name,".media WHERE parent_id='0' INTO @home_id");
    PREPARE stmt FROM @s;
    EXECUTE stmt ;
    DEALLOCATE PREPARE stmt;
 
    SET @s = CONCAT("SELECT IF(category = 'folder' , id,@home_id) 
      FROM ", _db_name,".media WHERE id =? INTO @home_id");
    PREPARE stmt FROM @s;
    EXECUTE stmt USING _nid;
    DEALLOCATE PREPARE stmt;

    IF _is_user = 1  THEN 
      SELECT 
        t.hub_id, 
        node_id, 
        node_id nid, 
        guest_id,
        guest_id uid, 
        t.id token, 
        _owner_id sender_id,
        _db_name db_name,
        u.email,
        CASE 
          WHEN yp.get_sysconf('guest_id')  = guest_id THEN 1 
          ELSE 0 
        END  is_public,
        IF(t.fingerprint IS null, 0, 1) require_password, 
        h.name title,
        _fullname `name`,
        _fullname `sender`, 
        @p privilege, 
        IF(@e=0, 'TICKET_OK', 'TICKET_EXPIRED') validity, 
        _is_user is_user
      FROM dmz_token t INNER JOIN dmz_user u ON u.id=t.guest_id
        INNER JOIN hub h ON h.id = t.hub_id 
        WHERE t.id = _token;
    ELSE 
      SELECT 
        t.hub_id, 
        @home_id as node_id, 
        @home_id nid, 
        guest_id, 
        guest_id uid, 
        t.id token, 
        _owner_id sender_id, 
        _db_name db_name,
        u.id as email,
        CASE 
          WHEN yp.get_sysconf('guest_id') = guest_id THEN 1 
          ELSE 0 
        END  is_public,
        IF(t.fingerprint IS null, 0, 1) require_password,
        h.name title,
        _fullname `name`, 
        _fullname `sender`,
        @p privilege, 
        IF(@e=0, 'TICKET_OK', 'TICKET_EXPIRED') validity,
        _is_user is_user
      FROM dmz_token t INNER JOIN dmz_media u on u.id=t.guest_id
        INNER JOIN hub h ON h.id = t.hub_id 
        WHERE t.id = _token;
    END IF; 
  END IF;

END$

DELIMITER ;