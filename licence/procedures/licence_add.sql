
DELIMITER $



DROP PROCEDURE IF EXISTS `licence_add`$
CREATE PROCEDURE `licence_add`(
 IN _profile JSON
)
BEGIN

  DECLARE  _domain_name  varchar(1000);
  DECLARE  _contact_email varchar(1000);
  DECLARE  _uid VARCHAR(16) CHARACTER SET ascii;
  DECLARE  _cid VARCHAR(16) CHARACTER SET ascii;
  DECLARE  _lid VARCHAR(16) CHARACTER SET ascii;
  DECLARE  _fid VARCHAR(16) CHARACTER SET ascii;
  DECLARE  _companyid VARCHAR(16) CHARACTER SET ascii;
  DECLARE _ctime int(11) unsigned;
  DECLARE _rollback BOOLEAN DEFAULT 0;  
  DECLARE _flag INT DEFAULT 0;  


  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET _rollback = 1;  
    GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
    @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
    SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);

  END;

  START TRANSACTION;

  SELECT JSON_UNQUOTE(JSON_EXTRACT(_profile, '$.domain_name'))  INTO _domain_name ;
  SELECT JSON_UNQUOTE(JSON_EXTRACT(_profile, '$.email'))  INTO _contact_email ;

  SELECT yp.uniqueId() INTO _uid;
  SELECT yp.uniqueId() INTO _cid;
  SELECT yp.uniqueId() INTO _lid;
  SELECT yp.uniqueId() INTO _fid;
  SELECT yp.uniqueId() INTO _companyid;

  SELECT UNIX_TIMESTAMP() INTO _ctime; 
  
  INSERT INTO company (id ,profile)
  SELECT  _companyid,  _profile ;


  INSERT INTO form (id,profile )
  SELECT  _fid,_profile;

  
  SELECT  1 INTO _flag  FROM user where email = _contact_email;
  
  INSERT INTO user(id,fingerprint,profile)
  SELECT _uid, UUID() , _profile  WHERE _flag = 0;


  SELECT id  INTO _uid FROM user WHERE email = _contact_email;

  INSERT INTO customer(id, user_id,form_id,company_id)
  SELECT  _cid, _uid,_fid ,_companyid;

  
  INSERT INTO licence (id,customer_id,`key`,start,end,status)
  SELECT   _lid ,  _cid , UUID() ,   _ctime ,_ctime,'active';


  IF _rollback THEN
    ROLLBACK;
      SELECT 1 as failed, @full_error AS reason;
  ELSE
      COMMIT;
      SELECT  0 as failed,
        fom.id token,
        l.key,
        l.status,
        fom.profile
      FROM 
      licence l
      INNER JOIN customer cus on l.customer_id = cus.id
      INNER JOIN company com on cus.company_id    = com.id 
      INNER JOIN form fom on cus.form_id    = fom.id 
      INNER JOIN user u on cus.user_id    = u.id
      WHERE 
      u.email = _contact_email  AND 
      fom.domain_name =_domain_name;

  END IF;

END$


DELIMITER ;

