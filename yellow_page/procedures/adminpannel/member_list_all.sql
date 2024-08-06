DELIMITER $

DROP PROCEDURE IF EXISTS `member_list_all`$
CREATE PROCEDURE `member_list_all`(
  IN _uid VARCHAR(16),
  IN _key VARCHAR(16)
)
BEGIN
  SELECT 
    o.id ogrid,
    o.name org_name,
    dm.id  domain_id,
    dm.name domain_name,
    d.id drumate_id,
    d.firstname,
    d.lastname,
    d.fullname,
    d.email,
    d.connected,
    d.username  ident,
    read_json_object(d.profile, "address")  `address`,
    read_json_object(d.profile, "personaldata")  personaldata,
    read_json_object(d.profile, "mobile")  mobile,
    read_json_object(d.profile, "areacode")  areacode, 
    p.privilege, 
    CASE WHEN IFNULL(read_json_object(d.profile, "mobile_verified"),'no') <> 'yes' THEN 'no' ELSE 'yes' END  mobile_verified,
    CASE WHEN IFNULL(read_json_object(d.profile, "email_verified"),'no') <> 'yes' THEN 'no' ELSE 'yes' END  email_verified,  
    e.status,
    IFNULL(JSON_UNQUOTE(JSON_EXTRACT(e.settings, '$.status_date')),null) status_date,
    d.otp
  FROM 
    privilege p 
    INNER JOIN organisation o ON p.domain_id=o.domain_id  
    INNER JOIN domain dm ON  dm.id = p.domain_id  
    INNER JOIN drumate d ON p.uid = d.id 
    INNER JOIN entity e  ON d.id = e.id 
    WHERE  (o.id =_key OR (o.domain_id = _key  
    AND LENGTH(_key) <> 16 ))  --  it is needed when _key is string & starting with digit
    --    EX  key is '79ghdttx..'  it pick the  79 domain members.
    AND  d.id <> _uid
    ORDER BY fullname ASC, d.id ASC;

END $


DELIMITER ;