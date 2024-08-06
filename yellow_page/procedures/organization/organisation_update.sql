


DELIMITER $

DROP PROCEDURE IF EXISTS `organisation_update`$
CREATE PROCEDURE `organisation_update`(
  _uid VARCHAR(16),
  _id VARCHAR(16),
  _name VARCHAR(512),
  _link VARCHAR(1024),
  _ident VARCHAR(80)
)
BEGIN

  IF _link IN ('') THEN 
    SELECT NULL INTO  _link;
  END IF;
  
  UPDATE organisation SET name=_name ,link=_link ,ident=_ident
  WHERE id = _id; 
  CALL  my_organisation(_uid);

END$

DELIMITER ;