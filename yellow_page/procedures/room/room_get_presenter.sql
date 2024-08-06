
DELIMITER $


-- =========================================================
-- room_get_presenter
-- =========================================================
DROP PROCEDURE IF EXISTS `room_get_presenter`$
CREATE PROCEDURE `room_get_presenter`(
  IN _hub_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN

  SELECT 
    r.hub_id, 
    d.id avatar_id,
    "presenter" role,
    r.id room_id,
    s.id ssid,
    d.id uid, 
    r.presenter_id,
    r.status,
    CONCAT(IFNULL(d.firstname, ''), ' ', IFNULL(d.lastname, '')) username
    FROM room r 
    INNER JOIN socket s ON r.presenter_id=s.id 
    INNER JOIN drumate d ON d.id=s.uid WHERE r.hub_id=_hub_id AND s.state='active';
END$

DELIMITER ;