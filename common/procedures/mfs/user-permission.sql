DELIMITER $
DROP FUNCTION IF EXISTS `user_permission`$
CREATE FUNCTION `user_permission`(
  _uid VARCHAR(512) CHARACTER SET ascii,
  _rid VARCHAR(16)  CHARACTER SET ascii
)
RETURNS TINYINT(2) DETERMINISTIC
BEGIN
  DECLARE _perm TINYINT(2) DEFAULT 0;
  DECLARE _db_name VARCHAR(60);
  DECLARE _category VARCHAR(60);
  DECLARE _file_path VARCHAR(1024);
  DECLARE _token VARCHAR(1024);
  DECLARE _parent_id VARCHAR(16) CHARACTER SET ascii;
  DECLARE _parent_perm TINYINT(4);

  SELECT category FROM media WHERE id=_rid INTO _category;
  SELECT IF(_uid IN ('*', 'ffffffffffffffff', 'nobody'), '*', _uid) INTO _uid;

  IF _category = "hub" THEN
    SELECT permission FROM permission 
      WHERE resource_id=_rid AND entity_id=_uid INTO _perm;
  ELSE
    SELECT IFNULL(permission, 0) FROM permission WHERE 
      (entity_id=_uid AND _uid != '*' AND resource_id='*') 
      ORDER BY permission DESC LIMIT 1
      INTO _perm;

    IF _perm THEN 
      RETURN _perm;
    ELSE -- SEARCH FROM WILDCARD ON resource_id
      SELECT IFNULL(permission, 0) FROM permission WHERE
        (entity_id IN (_uid, '*', 'ffffffffffffffff', 'nobody')) AND resource_id=_rid 
      ORDER BY permission DESC LIMIT 1
      INTO _perm;
    END IF;

    IF _perm THEN 
      RETURN _perm;
    ELSE -- SEARCH IN PARENT FROM TOKEN
      SELECT IFNULL(parent_permission(_uid, _rid), 0) INTO _perm;
    END IF;

    IF _perm THEN 
      RETURN _perm;
    ELSE -- SEARCH FROM WILDCARD ON accessor_id
      SELECT IFNULL(permission, 0) FROM permission WHERE 
        (entity_id= '*' AND resource_id=_rid) 
        ORDER BY permission DESC LIMIT 1
        INTO _perm;
    END IF;

    IF _perm THEN 
      RETURN _perm;
    ELSE -- SEARCH FROM WILDCARD ON user (uid)
      SELECT MAX(permission) FROM permission WHERE 
        (entity_id IN ('*', 'ffffffffffffffff', 'nobody') AND 
        (resource_id='*' OR resource_id=_rid) ) 
        ORDER BY permission DESC LIMIT 1
        INTO _perm;
    END IF;
    
  END IF;
  SELECT IFNULL(_perm, 0) INTO _perm;
  RETURN _perm;
END$

DELIMITER ;
