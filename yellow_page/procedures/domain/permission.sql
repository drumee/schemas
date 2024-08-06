DELIMITER $

DROP FUNCTION IF EXISTS `domain_permission`$
CREATE FUNCTION `domain_permission`(
  _uid VARCHAR(80),
  _dom_id INT,
  _perm TINYINT(6)
)
RETURNS TINYINT(6) DETERMINISTIC
BEGIN
  DECLARE _res TINYINT(6);
  SELECT privilege&_perm FROM privilege 
    WHERE `uid` = _uid AND domain_id=_dom_id INTO _res;
  RETURN IFNULL(_res, 0);
END$
DELIMITER ;

-- #####################
