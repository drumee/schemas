
DELIMITER $
DROP PROCEDURE IF EXISTS `disk_limit`$
CREATE PROCEDURE `disk_limit`(
  _entity_id  VARCHAR(16) CHARACTER SET ascii
)
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
  DECLARE _watermark VARCHAR(16)  CHARACTER SET ascii default "0";

  DECLARE _l_disk  double  default 0.0 ;

  DECLARE _q_share_hub  double  default 0.0 ;
  DECLARE _q_private_hub  double  default 0.0 ;
  DECLARE _cnt_share_hub int;
  DECLARE _cnt_private_hub int;

  SELECT id, owner_id  FROM yp.hub WHERE id = _entity_id  INTO _hub_id, _owner_id; 
  SELECT id FROM yp.drumate WHERE id = _entity_id  AND  _owner_id IS NULL  INTO _owner_id; 

  SELECT quota FROM yp.drumate WHERE id = _owner_id INTO _quota;

  IF _quota IS NULL THEN
    SELECT conf_value FROM sys_conf WHERE conf_key='default_quota' 
      INTO _watermark;
  END IF;
  SELECT JSON_VALUE(_quota, "$.disk") INTO _q_disk;
  SELECT JSON_VALUE(_quota, "$.desk_disk") INTO _q_desk_disk;
  SELECT JSON_VALUE(_quota, "$.hub_disk") INTO _q_hub_disk;
  SELECT IFNULL(_q_desk_disk,_q_disk) INTO _q_desk_disk;
  SELECT IFNULL(_q_hub_disk,_q_disk) INTO _q_hub_disk;

  SELECT JSON_VALUE(_quota, "$.share_hub") INTO _q_share_hub;
  SELECT JSON_VALUE(_quota, "$.private_hub") INTO _q_private_hub;

  --  hub_cnt
  SELECT 
    SUM(CASE WHEN e.area = 'private' then 1 else 0 END ),
    SUM(CASE WHEN e.area = 'share' then 1 else 0 END) 
    FROM 
      yp.hub h 
    INNER JOIN yp.entity e on e.id =  h.id
    WHERE 
    h.owner_id=_owner_id AND 
    e.area  IN ('private','share')  
    INTO  _cnt_private_hub, _cnt_share_hub ; 
       
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

    SELECT  IFNULL(_u_hub_disk, 0)  INTO _u_hub_disk;
    SELECT  IFNULL(_u_desk_disk, 0)  INTO _u_desk_disk;

    SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk, _q_desk_disk - _u_desk_disk ) INTO _l_disk;
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

    SELECT  IFNULL(_u_hub_disk, 0)  INTO _u_hub_disk;
    SELECT  IFNULL(_u_desk_disk, 0)  INTO _u_desk_disk;

    SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk, _q_hub_disk - _u_hub_disk ) INTO _l_disk;
     
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

    SELECT  IFNULL(_u_hub_disk, 0)  INTO _u_hub_disk;
    SELECT  IFNULL(_u_desk_disk, 0)  INTO _u_desk_disk;

    SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk, _q_desk_disk - _u_desk_disk ) INTO _l_disk;

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

      SELECT  IFNULL(_u_hub_disk, 0)  INTO _u_hub_disk;
      SELECT  IFNULL(_u_desk_disk, 0)  INTO _u_desk_disk;

      SELECT LEAST( _q_disk - _u_desk_disk - _u_hub_disk, _q_hub_disk - _u_hub_disk ) INTO _l_disk;

  END IF ;

  SELECT _hub_id  hub_id, 
  _owner_id owner_id,
  _quota quota,
  _org_id org_id,
  _entity_id entity_id,
  _u_desk_disk used_desk_disk,
  _u_hub_disk used_hub_disk,
  _q_disk quota_disk,
  _q_desk_disk quota_desk_disk, 
  _q_hub_disk quota_hub_disk,
  _l_disk available_disk,
  _q_share_hub quota_share_hub,  
  _q_private_hub quota_private_hub, 
  _cnt_share_hub used_share_hub,  
  _cnt_private_hub used_private_hub, 
  _q_share_hub - _cnt_share_hub  avaialable_share_hub, 
  _watermark watermark,
  _q_private_hub - _cnt_private_hub available_private_hub ;

END$




DELIMITER ;


