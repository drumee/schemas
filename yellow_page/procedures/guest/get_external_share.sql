DELIMITER $
DROP PROCEDURE IF EXISTS `get_external_share`$
CREATE PROCEDURE `get_external_share`(
     IN _share_id       VARCHAR(16)
)
BEGIN
  SELECT 
    -- n.owner_id AS oid,
    d.firstname AS firstname,
    d.lastname AS lastname, 
    n.resource_id  AS nid,
    s.id AS hub_id,
    n.message,
    n.permission,
    n.expiry_time
  FROM
    notification n
    INNER JOIN drumate d ON d.id= n.owner_id
    INNER JOIN share_box s ON s.owner_id = n.owner_id
    INNER JOIN guest g ON g.id = n.entity_id
  WHERE  
    n.share_id = _share_id AND 
    (n.expiry_time = 0 OR n.expiry_time > UNIX_TIMESTAMP());
END $

DELIMITER ;