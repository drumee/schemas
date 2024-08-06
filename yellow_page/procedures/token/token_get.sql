DELIMITER $
DROP PROCEDURE IF EXISTS `token_get_next`$
CREATE PROCEDURE `token_get_next`(
  IN _secret      VARCHAR(512)
)
BEGIN
  SELECT 
    t.email,
    t.name,
    t.secret,
    t.inviter_id,
    t.status,
    t.ctime,
    d.email as inviter_email,  
    t.method,
    t.metadata
  FROM 
  token t
  LEFT JOIN drumate d on d.id=t.inviter_id
  WHERE t.secret = _secret;
END$

DELIMITER ;