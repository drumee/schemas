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
    -- Multi-org: a secondary organisation (org_membership), only when the
    -- privilege table has nothing for this domain.
    IF _privilege = 0 AND NOT EXISTS (SELECT 1 FROM privilege WHERE uid = _uid AND domain_id = _domain_id) THEN
      SELECT privilege FROM org_membership WHERE uid = _uid AND domain_id = _domain_id INTO _privilege;
      SET _privilege = IFNULL(_privilege, 0);
    END IF;
    SELECT _privilege privilege, _is_authoritative is_authoritative;
  
END $


DELIMITER ;