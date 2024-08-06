DELIMITER $

DROP PROCEDURE IF EXISTS `token_generate_next`$
CREATE PROCEDURE `token_generate_next`(
  IN _email       VARCHAR(1024),
  IN _name      VARCHAR(512),
  IN _secret      VARCHAR(512),
  IN _method     VARCHAR(200),
  IN _inviter_id  VARCHAR(200)
)
BEGIN
  DECLARE _ctime INT(11); 
  DECLARE _metadata JSON ; 
  DELETE FROM token WHERE unix_timestamp() - ctime > 7*24*60*60;

  SELECT JSON_OBJECT("step","password") INTO _metadata ;  
  IF _method = 'b2bsignup' THEN 
    SELECT  JSON_OBJECT("step","company","mode","b2bsignup" ) INTO _metadata ;  
    SELECT 'signup' INTO _method; 
  END IF;

  IF  _inviter_id IS NULL THEN 
    -- This block is to avoid  the duplicate entries  in token table 
    -- Since mysql unique constraint did not consider null value and allow multiple records if any one of the candidate column has null value.    
    SELECT '' INTO  _inviter_id;
  END IF;

  SELECT UNIX_TIMESTAMP() INTO _ctime;
  REPLACE INTO 
    token 
    ( 
      email, 
      `name`, 
      `secret`, 
      method, 
      inviter_id, 
      `status`, 
      ctime,
      metadata
    ) 
    VALUES (
      _email, 
      _name, 
      _secret, 
      _method,
      _inviter_id,
      'active', 
      _ctime,
      _metadata 
    );

  SELECT 
    t.email,
    t.name,
    t.secret,
    t.method,
    t.inviter_id,
    t.status,
    t.ctime,
    t.metadata
  FROM 
    token t 
  WHERE t.secret = _secret;
END$

DELIMITER ;