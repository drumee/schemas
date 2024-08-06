DELIMITER $


DROP PROCEDURE IF EXISTS `member_list`$
CREATE PROCEDURE `member_list`(
  IN _uid VARCHAR(16),
  IN _role_id INT,
  IN _org_id VARCHAR(16),
  IN _key VARCHAR(200),
  IN _option VARCHAR(200),
  IN _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  DECLARE _owner_id VARCHAR(16);
  DECLARE _dom_id INT;
  CALL pageToLimits(_page, _offset, _range);

  SELECT owner_id, domain_id FROM yp.organisation WHERE id=_org_id INTO _owner_id , _dom_id;

  IF _role_id IN (0) THEN 
   SELECT NULL INTO  _role_id;
  END IF;

  IF  _role_id IS NOT NULL THEN 
    SELECT 
      _page as `page`,
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
      p.privilege , -- d.blocked,  d.archived, 
      e.status,
      IFNULL(JSON_UNQUOTE(JSON_EXTRACT(e.settings, '$.status_date')),null) status_date,
      d.otp, 
      CASE WHEN IFNULL(read_json_object(d.profile, "mobile_verified"),'no') <> 'yes' THEN 'no' ELSE 'yes' END  mobile_verified,
      CASE WHEN IFNULL(read_json_object(d.profile, "email_verified"),'no') <> 'yes' THEN 'no' ELSE 'yes' END  email_verified
    FROM 
      privilege p 
      INNER JOIN organisation o ON p.domain_id=o.domain_id  
      INNER JOIN domain dm ON  dm.id=p.domain_id  
      INNER JOIN drumate d ON  d.id=p.uid 
      INNER JOIN entity e  ON d.id=e.id 
      INNER JOIN map_role m ON p.uid=m.uid AND  o.id=m.org_id
    WHERE 
      o.id=_org_id  AND
      p.domain_id=_dom_id AND 
      m.role_id=_role_id   AND
      (CONCAT(d.firstname, ' ', d.lastname) LIKE CONCAT('%', TRIM(_key),'%') OR d.email LIKE CONCAT('%', TRIM(_key), '%')) AND
      CASE  
        WHEN _option='member' AND p.privilege=p.privilege THEN  1  
        WHEN _option='admin' AND  p.privilege  > 1 THEN  1  
        WHEN _option='nonadmin' AND  p.privilege=1 AND IFNULL(JSON_EXTRACT(d.profile, "$.mobile"),'-x-') <> '-x-'  THEN  1 
        WHEN _option='blocked' AND  e.status='locked' THEN  1 
        WHEN _option='archived' AND  e.status='archived' THEN  1 
        ELSE 0
      END=1 AND 
      CASE 
        WHEN e.status='archived' AND  _option IN ('member','admin' , 'nonadmin' ) THEN 1 
        ELSE 0 
      END=0 
     ORDER BY fullname ASC, d.id ASC
     LIMIT _offset, _range; 
  ELSE 
    SELECT
      _page as `page`,
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
      p.privilege, -- d.blocked,  d.archived ,
      e.status,
      IFNULL(JSON_UNQUOTE(JSON_EXTRACT(e.settings, '$.status_date')),null) status_date,
      d.otp, 
      CASE WHEN IFNULL(read_json_object(d.profile, "mobile_verified"),'no') <> 'yes' THEN 'no' ELSE 'yes' END  mobile_verified,
      CASE WHEN IFNULL(read_json_object(d.profile, "email_verified"),'no') <> 'yes' THEN 'no' ELSE 'yes' END  email_verified
    FROM 
      privilege p 
      INNER JOIN organisation o ON p.domain_id=o.domain_id  
      INNER JOIN domain dm ON  dm.id=p.domain_id  
      INNER JOIN drumate d ON p.uid=d.id 
      INNER JOIN entity e  ON d.id=e.id 
    WHERE 
      o.id=_org_id AND 
      p.domain_id=_dom_id AND 
      (CONCAT(d.firstname, ' ', d.lastname) LIKE CONCAT('%', TRIM(_key),'%') OR d.email LIKE CONCAT('%', TRIM(_key), '%')) AND
      CASE
        WHEN _option='member' AND p.privilege=p.privilege AND p.privilege >0 THEN  1  
        WHEN _option='admin' AND p.privilege > 1 THEN  1  
        WHEN _option='nonadmin' AND  p.privilege=1 AND IFNULL(JSON_EXTRACT(d.profile, "$.mobile"),'-x-') <> '-x-' THEN  1 
        WHEN _option='blocked' AND  e.status='blocked' THEN  1 
        WHEN _option='archived' AND  e.status='archived' THEN  1 
        ELSE 0 
      END=1 AND 
      CASE 
        WHEN e.status='archived' AND _option IN ('member','admin' , 'nonadmin' ) THEN 1 
        ELSE 0 
      END=0 
      ORDER BY fullname ASC, d.id ASC
      LIMIT _offset, _range;    
   END IF; 
END $


DELIMITER ;