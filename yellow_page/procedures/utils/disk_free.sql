DELIMITER $
DROP FUNCTION IF EXISTS `disk_used`$
DROP FUNCTION IF EXISTS `disk_free`$
CREATE FUNCTION `disk_free`(
  _entity_id  VARCHAR(16) CHARACTER SET ascii
) RETURNS double
DETERMINISTIC
BEGIN
  DECLARE _uid VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _hub_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _owner_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _drumate_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _org_id VARCHAR(16)  CHARACTER SET ascii;
  DECLARE _quota json ;

  DECLARE _u_desk_disk  double  default 0.0 ;
  DECLARE _u_hub_disk  double  default 0.0 ;


  DECLARE _q_desk_disk  double  default 0.0 ;
  DECLARE _q_hub_disk  double  default 0.0 ;
  DECLARE _q_disk  double  default 0.0 ;


  DECLARE _l_disk  double  default 0.0 ;

  SELECT id, owner_id  FROM yp.hub WHERE id = _entity_id  INTO _hub_id , _owner_id; 
  SELECT id FROM yp.drumate WHERE id = _entity_id  AND  _owner_id IS NULL  INTO _owner_id; 

  SELECT quota FROM yp.drumate WHERE id = _owner_id INTO _quota;

  SELECT o.id
  FROM  yp.drumate d  
  INNER JOIN yp.organisation o ON o.domain_id= d.domain_id
  WHERE d.id =  _owner_id AND  d.domain_id > 1  INTO _org_id;
    SELECT JSON_VALUE(_quota, "$.disk") INTO _q_disk;
    SELECT JSON_VALUE(_quota, "$.desk_disk") INTO _q_desk_disk;
    SELECT JSON_VALUE(_quota, "$.hub_disk") INTO _q_hub_disk;
    SELECT IFNULL(_q_desk_disk,_q_disk) INTO _q_desk_disk;
    SELECT IFNULL(_q_hub_disk,_q_disk) INTO _q_hub_disk;


  --  DESK USAGE
  IF (_hub_id IS NULL AND _org_id IS NULL) THEN 

      SELECT 
        SUM(du.size) 
        FROM 
        yp.disk_usage du
        INNER JOIN yp.hub h ON du.hub_id = h.id
        WHERE h.owner_id=_owner_id INTO _u_hub_disk;
      SELECT 
        SUM(du.size) 
        FROM 
        yp.disk_usage du
        INNER JOIN yp.drumate d ON du.hub_id = d.id
        WHERE d.id=_owner_id  INTO _u_desk_disk;

      SELECT  IFNULL(_u_hub_disk , 0)  INTO _u_hub_disk;
      SELECT  IFNULL(_u_desk_disk , 0)  INTO _u_desk_disk;

      SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk   , _q_desk_disk - _u_desk_disk ) INTO _l_disk;

  END IF ;

 --  hub USAGE
  IF (_hub_id IS NOT NULL AND _org_id IS NULL) THEN 

      SELECT 
        SUM(du.size) 
        FROM 
        yp.disk_usage du
        INNER JOIN yp.hub h ON du.hub_id = h.id
        WHERE h.owner_id=_owner_id INTO _u_hub_disk;
    
        
      SELECT 
        SUM(du.size) 
        FROM 
        yp.disk_usage du
        INNER JOIN yp.drumate d ON du.hub_id = d.id
        WHERE d.id=_owner_id  INTO _u_desk_disk;

      SELECT  IFNULL(_u_hub_disk , 0)  INTO _u_hub_disk;
      SELECT  IFNULL(_u_desk_disk , 0)  INTO _u_desk_disk;

      SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk  , _q_hub_disk - _u_hub_disk ) INTO _l_disk;
     
  END IF ;



  --  DESK USAGE
  IF (_hub_id IS NULL AND _org_id IS NOT  NULL) THEN 

     SELECT 
        SUM(du.size) 
        FROM 
        yp.disk_usage du
        INNER JOIN yp.hub h ON du.hub_id = h.id
        INNER JOIN yp.map_role m ON  h.owner_id = m.uid
        WHERE m.org_id=_org_id INTO _u_hub_disk;	
        
    SELECT 
        SUM(du.size) 
        FROM 
        yp.disk_usage du
        INNER JOIN yp.drumate d ON du.hub_id = d.id
        INNER JOIN yp.map_role m ON  d.id = m.uid
        WHERE  m.org_id=_org_id INTO _u_desk_disk;

      SELECT  IFNULL(_u_hub_disk , 0)  INTO _u_hub_disk;
      SELECT  IFNULL(_u_desk_disk , 0)  INTO _u_desk_disk;

      SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk   , _q_desk_disk - _u_desk_disk ) INTO _l_disk;

  END IF ;

 --  hub USAGE
  IF (_hub_id IS NOT NULL AND _org_id IS NOT NULL) THEN 

      SELECT 
        SUM(du.size) 
        FROM 
        yp.disk_usage du
        INNER JOIN yp.hub h ON du.hub_id = h.id
        INNER JOIN yp.map_role m ON  h.owner_id = m.uid
        WHERE m.org_id=_org_id INTO _u_hub_disk;	
        
      SELECT 
        SUM(du.size) 
        FROM 
        yp.disk_usage du
        INNER JOIN yp.drumate d ON du.hub_id = d.id
        INNER JOIN yp.map_role m ON  d.id = m.uid
        WHERE  m.org_id=_org_id INTO _u_desk_disk;

      SELECT  IFNULL(_u_hub_disk , 0)  INTO _u_hub_disk;
      SELECT  IFNULL(_u_desk_disk , 0)  INTO _u_desk_disk;

      SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk   , _q_hub_disk - _u_hub_disk ) INTO _l_disk;

  END IF ;

  RETURN _l_disk;

END$



DELIMITER ;


