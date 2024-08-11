DELIMITER $


-- =======================================================================
-- Create a poll
-- WILL BE OBSOLETED
-- =======================================================================
DROP PROCEDURE IF EXISTS `poll_create`$
CREATE PROCEDURE `poll_create`(
  IN _ident VARCHAR(80),
  IN _name VARCHAR(80),
  IN _referer VARCHAR(500),
  IN _ip VARCHAR(40)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _id VARCHAR(16);

  SELECT uniqueId(), UNIX_TIMESTAMP() into _id, _now;

  INSERT INTO
    poll VALUES(_id, _ident, _name, _now, _referer, _ip);
  SELECT * FROM poll WHERE id = _id;

END$

-- =======================================================================
-- Initialize a new poll
-- =======================================================================
DROP PROCEDURE IF EXISTS `poll_init`$
CREATE PROCEDURE `poll_init`(
  IN _auth_id VARCHAR(16),
  IN _ident VARCHAR(80),
  IN _name VARCHAR(80),
  IN _referer VARCHAR(500),
  IN _ip VARCHAR(40)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _id VARCHAR(16);

  SELECT uniqueId(), UNIX_TIMESTAMP() into _id, _now;

  INSERT INTO
    poll VALUES(_id, _auth_id, _ident, _name, _now, _referer, _ip);
  SELECT
    poll.id as id,
    author_id,
    ident,
    `name`,
    ctime,
    referer,
    ip,
    concat(firstname, ' ', lastname) as author
  FROM poll left join yp.drumate ON drumate.id=author_id WHERE id = _id;

END$

-- =======================================================================
-- Get a poll
-- =======================================================================
DROP PROCEDURE IF EXISTS `poll_get`$
CREATE PROCEDURE `poll_get`(
  IN _key VARCHAR(80)
)
BEGIN

  SELECT
    poll.id as id,
    author_id,
    ident,
    `name`,
    ctime,
    referer,
    ip,
    concat(firstname, ' ', lastname) as author
  FROM poll left join yp.drumate ON drumate.id=author_id WHERE id = _key;

END$


DELIMITER ;
