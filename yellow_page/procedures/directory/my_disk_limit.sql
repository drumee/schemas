DELIMITER $

DROP PROCEDURE IF EXISTS `my_disk_limit`$
CREATE PROCEDURE `my_disk_limit`(
  _uid  VARCHAR(16) CHARACTER SET ascii
)
BEGIN

  DECLARE _desk_disk  double  default 0.0 ;
  DECLARE _private_disk  double  default 0.0 ;
  DECLARE _chat_disk  double  default 0.0 ;
  DECLARE _share_disk  double  default 0.0 ;

  DECLARE _quota json ;
  DECLARE _q_desk_disk  double  default 0.0 ;
  DECLARE _q_hub_disk  double  default 0.0 ;
  DECLARE _q_disk  double  default 0.0 ;
  DECLARE _watermark VARCHAR(16)  CHARACTER SET ascii default "0";


  SELECT quota FROM yp.drumate WHERE id = _uid INTO _quota;
  SELECT JSON_VALUE(_quota, "$.watermark") INTO _watermark;
  SELECT JSON_VALUE(_quota, "$.disk") INTO _q_disk;
  SELECT JSON_VALUE(_quota, "$.desk_disk") INTO _q_desk_disk;
  SELECT JSON_VALUE(_quota, "$.hub_disk") INTO _q_hub_disk;
  SELECT IFNULL(_q_desk_disk,_q_disk) INTO _q_desk_disk;
  SELECT IFNULL(_q_hub_disk,_q_disk) INTO _q_hub_disk;



  SELECT 
    SUM(CASE WHEN e.area = 'dmz' THEN du.size ELSE 0 END ) chat,
    SUM(CASE WHEN e.area = 'private' THEN du.size ELSE 0 END ) private,
    SUM(CASE WHEN e.area = 'share' THEN du.size ELSE 0 END) share
  FROM 
    yp.disk_usage du
    INNER JOIN yp.hub h ON du.hub_id = h.id
    INNER JOIN entity e ON e.id = du.hub_id
    WHERE h.owner_id=_uid 
    INTO _chat_disk, _private_disk, _share_disk;

  SELECT 
    SUM(du.size) 
  FROM 
    yp.disk_usage du
    INNER JOIN yp.drumate d ON du.hub_id = d.id
    WHERE d.id=_uid
    INTO _desk_disk;

  SELECT _q_disk quota_disk, 
    _chat_disk chat, 
    _private_disk private, 
    _share_disk share, 
    _desk_disk desk,
    _watermark watermark
  ;


END$

DELIMITER ;


