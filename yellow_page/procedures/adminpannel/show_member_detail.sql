DELIMITER $


DROP PROCEDURE IF EXISTS `show_member_detail`$
CREATE PROCEDURE `show_member_detail`(
  IN _drumate_id  VARCHAR(16) CHARACTER SET ascii,
  IN _org_id VARCHAR(16) CHARACTER SET ascii
 )
BEGIN
    SELECT 
      dm.id  domain_id,
      dm.name domain_name,
      read_json_object(d.profile, "surname")  `surname`,
      d.id drumate_id,
      d.firstname,
      d.lastname,
      d.fullname,
      d.email,
      d.connected,
      d.username  ident,
      p.privilege ,
      -- d.blocked,  
      -- d.archived,
      e.status,
      IFNULL(JSON_UNQUOTE(JSON_EXTRACT(e.settings, '$.status_date')),null) status_date,
      CASE WHEN e.status = 'archived' AND  (IFNULL(JSON_UNQUOTE(JSON_EXTRACT(e.settings, '$.status_date')),UNIX_TIMESTAMP())  + (60*60*24*15) ) >= UNIX_TIMESTAMP() 
      THEN 'yes'  ELSE 'no'  END  is_able_delete,
      d.otp,
      read_json_object(d.profile, "address")  `address`,
      read_json_object(d.profile, "personaldata")  personaldata,
      read_json_object(d.profile, "mobile")  mobile, 
      read_json_object(d.profile, "areacode")  areacode, 
      CASE WHEN IFNULL(read_json_object(d.profile, "mobile_verified"),'no') <> 'yes' THEN 'no' ELSE 'yes' END  mobile_verified,
      CASE WHEN IFNULL(read_json_object(d.profile, "email_verified"),'no') <> 'yes' THEN 'no' ELSE 'yes' END  email_verified
     
    FROM 
      privilege p 
      INNER JOIN organisation o ON p.domain_id=o.domain_id  
      INNER JOIN domain dm ON  dm.id = p.domain_id  
      INNER JOIN drumate d ON p.uid = d.id 
      INNER JOIN entity e  ON d.id = e.id 
    WHERE  
      o.id =_org_id  AND  d.id =_drumate_id ; 
END $

DELIMITER ;