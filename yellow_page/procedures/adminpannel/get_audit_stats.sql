DELIMITER $

DROP PROCEDURE IF EXISTS `get_audit_stats`$
CREATE PROCEDURE `get_audit_stats`(
  IN _domain_id INT(11) UNSIGNED,
  IN _from_time INT(11),
  IN _to_time INT(11)
)
BEGIN

  DECLARE _storage_used FLOAT DEFAULT 0;

  SELECT COALESCE(SUM(e.space), 0)
  INTO _storage_used
  FROM yp.entity e
  WHERE e.dom_id = _domain_id
    AND e.type = 'hub'
    AND e.status = 'active';

  SELECT _storage_used AS storage_used_bytes;
END$

DELIMITER ;
