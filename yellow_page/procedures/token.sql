DELIMITER $


DROP PROCEDURE IF EXISTS `token_update`$
CREATE PROCEDURE `token_update`(
 IN _secret      VARCHAR(512),
 IN _metadata JSON 
)
BEGIN
  UPDATE token SET metadata = _metadata WHERE secret = _secret;
END$

DROP PROCEDURE IF EXISTS `token_btob_update1`$
-- DROP PROCEDURE IF EXISTS `token_btob_update`$
-- CREATE PROCEDURE `token_btob_update`(
--  IN _secret      VARCHAR(512),
--  IN _metadata JSON 
-- )
-- BEGIN
--   DECLARE _ctime INT(11); 
--   UPDATE organisation_token SET metadata = _metadata WHERE secret = _secret;

-- END$

--DROP PROCEDURE IF EXISTS `token_generate`$
DROP PROCEDURE IF EXISTS `token_generate_signup`$
-- CREATE PROCEDURE `token_generate_signup`(
--   IN _email       VARCHAR(1024),
--   IN _secret      VARCHAR(512),
--   IN _method     VARCHAR(200)
-- )
-- BEGIN
--   DECLARE _ctime INT(11); 
--   SELECT UNIX_TIMESTAMP() INTO _ctime;
--   REPLACE INTO token VALUES(NULL, _email, _email, _secret, _method, null ,'active',_ctime);
--   SELECT * FROM token WHERE secret = _secret;
-- END$

-- ====================================================================
-- 
-- ====================================================================
DROP PROCEDURE IF EXISTS `token_generate_next`$

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
    -- DELETE FROM token WHERE email = _email AND method = _method;  
  END IF;

  -- IF _inviter_id IN ('',  '0') THEN 
  --   SELECT NULL INTO  _inviter_id;
  -- END IF;


  SELECT UNIX_TIMESTAMP() INTO _ctime;

  REPLACE INTO token (email,name,secret,method,inviter_id,status,ctime,metadata) 
    VALUES (_email, _name, _secret, _method,_inviter_id,'active', _ctime,_metadata );

  SELECT 
    t.email,t.name,t.secret,t.method,t.inviter_id,t.status,t.ctime,t.metadata
  FROM 
    token t 
    -- LEFT JOIN organisation_token o ON t.secret= o.secret
  WHERE t.secret = _secret;
END$

-- ====================================================================
-- 
-- ====================================================================
DROP PROCEDURE IF EXISTS `token_get_next`$
CREATE PROCEDURE `token_get_next`(
  IN _secret      VARCHAR(512)
)
BEGIN

  -- DELETE FROM token WHERE UNIX_TIMESTAMP() - expiry;
  SELECT 
    t.email,
    t.name,
    t.secret,
    t.inviter_id,
    t.status,
    t.ctime,
    d.email as inviter_email,  
    CASE WHEN  JSON_VALUE(metadata, "$.mode")  IS NOT NULL THEN 'b2bsignup' ELSE t.method END method , 
    t.metadata
  FROM 
  token t
  -- LEFT JOIN organisation_token o ON t.secret= o.secret  
  LEFT JOIN drumate d on d.id=t.inviter_id
  WHERE t.secret = _secret;

END$


-- ====================================================================
-- 
-- ====================================================================
DROP PROCEDURE IF EXISTS `token_delete`$
CREATE PROCEDURE `token_delete`(
  IN _secret      VARCHAR(512)
)
BEGIN
  DELETE FROM token WHERE secret = _secret; 
  DELETE FROM organisation_token WHERE secret = _secret; 
END$

-- ====================================================================
-- 
-- ====================================================================
DROP PROCEDURE IF EXISTS `token_check`$
CREATE PROCEDURE `token_check`(
  IN _email       VARCHAR(1024),
  IN _secret      VARCHAR(512),
  IN _method     VARCHAR(200)
)
BEGIN
  SELECT *, (UNIX_TIMESTAMP() - ctime) AS age FROM token WHERE 
    secret=secret AND email=_email AND method=_method;
END$

DELIMITER ;