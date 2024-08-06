DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invitation_status`$
CREATE PROCEDURE `contact_invitation_status`(
  IN _secret  VARCHAR(255),
  IN _uid  VARCHAR(16) 
)
BEGIN

  DECLARE _email VARCHAR(255); 
  DECLARE _inviter_id  VARCHAR(16) ;
  DECLARE _invitee_id  VARCHAR(16) ;
  
  DECLARE _status VARCHAR(255) DEFAULT 'nodata' ; 
  DECLARE _userdb VARCHAR(255); 
  DECLARE _contact_id VARCHAR(16) ;
  DECLARE _message VARCHAR(5000) ;
  
  IF _uid IN ('',  '0') THEN 
   SELECT NULL INTO  _uid;
  END IF;

  SELECT email,inviter_id FROM token WHERE secret =_secret INTO _email,_inviter_id;
  SELECT id   FROM drumate WHERE email =_email INTO _invitee_id;
 
 IF (IFNULL((SELECT 1 FROM token WHERE secret =_secret), 0)  = 1 ) THEN

    SELECT 'unregister' FROM token WHERE   _uid IS NULL AND secret =_secret INTO _status;
    SELECT 'register'   FROM drumate WHERE _uid IS NULL AND  email =_email INTO _status;
    SELECT 'invalid'    WHERE              _uid IS NOT NULL AND  IFNULL(_invitee_id,'-99') != _uid  INTO  _status; 

    SELECT db_name FROM yp.entity WHERE id=_uid  INTO _userdb;

    SELECT NULL,NULL,NULL INTO @_contact_id,@_status,@_message;
    
    IF _userdb IS NOT NULL AND IFNULL(_invitee_id,'-99') = _uid   THEN
      SET @st = CONCAT("SELECT id,status,message FROM  " , _userdb ,".contact WHERE entity = ? INTO @_contact_id,@_status,@_message");
      PREPARE stamt FROM @st;
      EXECUTE stamt USING _inviter_id;
      DEALLOCATE PREPARE stamt;
    END IF;

    SELECT  @_status  WHERE  @_status  IS NOT NULL INTO _status ;
 END IF; 

  SELECT _status status,@_contact_id contact_id , @_message message;

END $

DELIMITER ;

