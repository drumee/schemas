DELIMITER $
-- ==============================================================
-- To get public link
-- ==============================================================
DROP PROCEDURE IF EXISTS `get_node_link`$
CREATE PROCEDURE `get_node_link`( 
   IN _src_id VARCHAR(16),
   IN _uid VARCHAR(16)
)
BEGIN
DECLARE _rid VARCHAR(16);
DECLARE _eid VARCHAR(16);
DECLARE _vhost VARCHAR(255);
  
  SELECT m.id ,p.entity_id 
  FROM permission p 
  INNER JOIN media m ON 
    m.id = p.resource_id 
  WHERE m.id =_src_id 
        AND p.entity_id = _uid
        AND p.assign_via='link' 
        INTO _rid,_eid ;

  SELECT 
    d.firstname,
    d.lastname,
    d.email,
    CONCAT ('https://',yp.get_vhost(e.ident),'/#/share/',_rid,'/',_eid) link
  FROM yp.entity e
  INNER JOIN yp.hub sb on sb.id = e.id
  INNER JOIN yp.drumate d on d.id = sb.owner_id
  WHERE e.db_name= DATABASE() AND _rid IS NOT NULL AND _eid IS NOT NULL ;
END $

-- ==============================================================
-- To get public link
-- ==============================================================
DROP PROCEDURE IF EXISTS `mfs_get_dmz_link`$
CREATE PROCEDURE `mfs_get_dmz_link`( 
   IN _src_id VARCHAR(16),
   IN _uid VARCHAR(16)
)
BEGIN
DECLARE _rid VARCHAR(16);
DECLARE _eid VARCHAR(16);
DECLARE _vhost VARCHAR(255);
  
  SELECT m.id ,p.entity_id 
  FROM permission p 
  INNER JOIN media m ON 
    m.id = p.resource_id 
  WHERE m.id =_src_id 
    AND p.entity_id = _uid
    AND p.assign_via='link' 
    INTO _rid,_eid ;

  SELECT 
    d.firstname,
    d.lastname,
    d.email,
    _rid AS nid,
    _eid AS entity_id
  FROM yp.entity e
  INNER JOIN yp.hub sb on sb.id = e.id
  INNER JOIN yp.drumate d on d.id = sb.owner_id
  WHERE e.db_name= DATABASE() AND _rid IS NOT NULL AND _eid IS NOT NULL ;
END $

DELIMITER ;