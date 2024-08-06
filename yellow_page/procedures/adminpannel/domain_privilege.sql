DELIMITER $

DROP PROCEDURE IF EXISTS `domain_privilege`$
CREATE PROCEDURE `domain_privilege`(
  IN _domain_id INT,
  IN _uid VARCHAR(16)
)
BEGIN
    DECLARE _privilege TINYINT(4) DEFAULT  0;
    DECLARE _is_authoritative TINYINT(4) DEFAULT  0;
    SELECT privilege ,is_authoritative FROM privilege WHERE uid = _uid  AND domain_id = _domain_id INTO _privilege , _is_authoritative ; 
    SELECT _privilege privilege, _is_authoritative is_authoritative;
  
END $

DELIMITER ;