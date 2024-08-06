DELIMITER $

DROP PROCEDURE IF EXISTS `get_pr_node_attr`$
CREATE PROCEDURE `get_pr_node_attr`(
   IN _node_id VARCHAR(16)
)
BEGIN

  SELECT 
    d.id entity_id ,  
    user_permission (d.id ,_node_id ) AS privilege, 
    d.email email,
    _node_id resource_id,
    yp.duration_days( user_expiry(d.id ,_node_id ))days,
    yp.duration_hours( user_expiry(d.id ,_node_id ))hours,
    read_json_object(d.profile, 'firstname') AS firstname,
    read_json_object(d.profile, 'lastname') AS lastname
  FROM
  (SELECT distinct entity_id FROM permission WHERE  expiry_time <>-1 ) p
  INNER JOIN yp.drumate d on p.entity_id=d.id 
  WHERE  user_permission (d.id ,_node_id ) > 0 ;

END$



DELIMITER ;
