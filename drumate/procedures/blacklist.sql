-- =========================================================
-- db/schemas/drumate/procedures/blacklist.sql
-- =========================================================

DELIMITER $

-- =========================================================
-- Gets blacklists of drumate.
-- =========================================================
DROP PROCEDURE IF EXISTS `blacklist_show`$
CREATE PROCEDURE `blacklist_show`(
  _page INT(6)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  SELECT d.id AS id, d.email AS email,
  JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.firstname')) AS firstname,
  JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.lastname'))  AS lastname,
  JSON_UNQUOTE(JSON_EXTRACT(d.profile, '$.mobile'))  AS mobile,
  _page AS page
  FROM yp.drumate d JOIN blacklist b ON d.email = b.email
  ORDER BY CONCAT(firstname, ' ', lastname) ASC, email ASC LIMIT _offset, _range;
END$

-- =========================================================
-- 
-- =========================================================
DROP PROCEDURE IF EXISTS `blacklist_add`$
CREATE PROCEDURE `blacklist_add`(
  IN _emails    MEDIUMTEXT
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  WHILE _i < JSON_LENGTH(_emails) DO 
    INSERT IGNORE INTO blacklist VALUES(
      null, 
      JSON_UNQUOTE(JSON_EXTRACT(_emails, CONCAT("$[", _i, "]"))), 
      UNIX_TIMESTAMP()
    );
    SELECT _i + 1 INTO _i;
  END WHILE;
END$

-- =========================================================
--
-- =========================================================
DROP PROCEDURE IF EXISTS `blacklist_delete`$
CREATE PROCEDURE `blacklist_delete`(
  IN _emails    MEDIUMTEXT
)
BEGIN
  DECLARE _i INTEGER DEFAULT 0;
  WHILE _i < JSON_LENGTH(_emails) DO 
    DELETE FROM blacklist 
      WHERE email = JSON_UNQUOTE(JSON_EXTRACT(_emails, CONCAT("$[", _i, "]")));
    SELECT _i + 1 INTO _i;
  END WHILE;
END$


DELIMITER ;
