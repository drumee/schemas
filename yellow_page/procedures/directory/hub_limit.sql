DELIMITER $
DROP PROCEDURE IF EXISTS `hub_limit`$
CREATE PROCEDURE `hub_limit`(
  _uid  VARCHAR(16) CHARACTER SET ascii
)
BEGIN

  DECLARE _q_share_hub  double  default 0.0 ;
  DECLARE _q_private_hub  double  default 0.0 ;
  DECLARE _cnt_share_hub int;
  DECLARE _cnt_private_hub int;
  DECLARE _quota json ;

  SELECT quota FROM yp.drumate WHERE id = _uid INTO _quota;
  IF _quota IS NULL THEN
    SELECT 10000 INTO _q_share_hub;
    SELECT 10000 INTO _q_private_hub;
  ELSE
    SELECT JSON_VALUE(_quota, "$.share_hub") INTO _q_share_hub;
    SELECT JSON_VALUE(_quota, "$.private_hub") INTO _q_private_hub;
  END IF;

  --  hub_cnt
  SELECT 
    SUM(CASE WHEN e.area = 'private' then 1 else 0 END ) ,
    SUM(CASE WHEN e.area = 'share' then 1 else 0 END) 
    FROM 
      yp.hub h 
    INNER JOIN yp.entity e on e.id =  h.id
    WHERE 
    h.owner_id=_uid  
    INTO  _cnt_private_hub, _cnt_share_hub ;


-- SELECT _cnt_private_hub, _cnt_share_hub ;

SELECT  _q_share_hub quota_share_hub  ,  
  _q_private_hub quota_private_hub, 
  _cnt_share_hub   used_share_hub, 
  _cnt_private_hub  used_private_hub, 
  _q_share_hub - _cnt_share_hub  avaialable_share_hub ,   
  _q_private_hub - _cnt_private_hub    available_private_hub;

END$


DELIMITER ;


