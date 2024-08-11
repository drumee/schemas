DELIMITER $

-- =========================================================
--
-- FRONT OFFICE STUFFS
--
-- =========================================================

-- =======================================================================
-- Get _number top (latest) news from public communities
-- =======================================================================
DROP PROCEDURE IF EXISTS `top_news`$
CREATE PROCEDURE `top_news`(
  IN _page TINYINT(8)
)
BEGIN

  DECLARE _more_rows BOOLEAN DEFAULT TRUE;
  DECLARE _did VARBINARY(16);
  DECLARE _cid VARBINARY(16);
  DECLARE _aid VARBINARY(16);
  DECLARE _cname VARCHAR(80);
  DECLARE _area VARCHAR(80);
  DECLARE _offset BIGINT DEFAULT 0;
  DECLARE _range BIGINT DEFAULT 2;

  DECLARE threads_list CURSOR FOR SELECT resource_id, cid, cname, area, aid
    FROM billboard_view WHERE category='blog' ORDER BY time_stamp DESC
    LIMIT _offset,_range;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _more_rows = FALSE;

  IF @rows_per_page IS NULL THEN
    SET @rows_per_page=15;
  END IF;

  SELECT (_page - 1)*@rows_per_page, (_page)*@rows_per_page INTO _offset,_range;

  OPEN threads_list;

  cloop: LOOP
    FETCH threads_list INTO _did, _cid, _cname, _area, _aid;
    IF NOT _more_rows THEN
      LEAVE cloop;
    END IF;
    SET @s = CONCAT ("SELECT ",
      "author_id, subject, summary, ptime, firstname, lastname, fullname, attach, tid, ",
      "from_unixtime(ptime, ", quote( @dformat), ") AS date, ", _page, " AS page, ",
      quote(_cid),   " AS cid, ",
      quote(_did),   " AS did, ",
      quote(_cname), " AS cname, ",
      quote(_area),  " AS area, ",
      quote(_aid),   " AS aid, ",
      " attach ",
      " FROM `C_", _cid, "`.drums_summary WHERE did=", quote(_did));
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
   END LOOP cloop;

  CLOSE threads_list;
END$


-- =======================================================================
-- Get _number top (latest) news from public communities
-- =======================================================================
DROP PROCEDURE IF EXISTS `gallery`$
CREATE PROCEDURE `gallery`(
  IN _category VARCHAR(50),
  IN _page TINYINT(4)
)
BEGIN

  DECLARE _more_rows BOOLEAN DEFAULT TRUE;
  DECLARE _offset BIGINT DEFAULT 0;
  DECLARE _range BIGINT DEFAULT 2;
  DECLARE _rid VARBINARY(16);
  DECLARE _cid VARBINARY(16);
  DECLARE _aid VARBINARY(16);
  DECLARE _cname VARCHAR(80);
  DECLARE _area VARCHAR(80);
  DECLARE _home_dir VARCHAR(255);


  DECLARE threads_list CURSOR FOR SELECT resource_id, cid, cname, area, aid, home_dir
    FROM billboard_view WHERE category=_category ORDER BY time_stamp DESC LIMIT _offset,_range;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _more_rows = FALSE;

  IF @rows_per_page IS NULL THEN
    SET @rows_per_page=15;
  END IF;

  SELECT (_page - 1)*@rows_per_page, (_page)*@rows_per_page INTO _offset,_range;

  OPEN threads_list;

  cloop: LOOP
    FETCH threads_list INTO _rid, _cid, _cname, _area, _aid, _home_dir;
    IF NOT _more_rows THEN
      LEAVE cloop;
    END IF;
    SET @s = CONCAT ("SELECT ", _page, " AS page, ",
      "author_id, summary, ptime, firstname, lastname, fullname, cid, ",
      "category AS filetype, filesize, ",
      quote(_area), " AS area, ", quote(_aid), " AS aid, ",
      quote(_cname), " AS cname, nid,  cid AS oid, ",
      "CONCAT (", quote(_home_dir), ", file_path) AS file_path ",
      " FROM `C_", _cid, "`.gallery_view WHERE nid=", quote(_rid));
    PREPARE stmt FROM @s;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
   END LOOP cloop;

  CLOSE threads_list;
END$


-- =======================================================================
-- BROKEN ???
-- =======================================================================
DROP PROCEDURE IF EXISTS `news_flow`$
CREATE PROCEDURE `news_flow`(
  IN _category VARCHAR(50),
  IN _page TINYINT(4)
)
BEGIN
  DECLARE _offset BIGINT DEFAULT 0;
  DECLARE _range BIGINT DEFAULT 2;

  IF @rows_per_page IS NULL THEN
    SET @rows_per_page=15;
  END IF;

  SELECT (_page - 1)*@rows_per_page, (_page)*@rows_per_page INTO _offset,_range;

  SELECT _page as `page`, resource_id, source_id, summary, author_id FROM news_flow WHERE category=_category ORDER BY time_stamp DESC LIMIT _offset,_range;

END$

-- =======================================================================
-- Register visitor request  WILL BE DEPRECATED
-- =======================================================================
DROP PROCEDURE IF EXISTS `register_touch_request`$
CREATE PROCEDURE `register_touch_request`(
  IN _firstname VARCHAR(255),
  IN _lastname VARCHAR(255),
  IN _email VARCHAR(255),
  IN _message TEXT,
  IN _reason VARCHAR(16)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _cksum VARCHAR(255);

  SELECT UNIX_TIMESTAMP() into _now;
  SELECT sha2(uuid(),224) INTO _cksum;

  INSERT INTO
    request (`firstname`,`lastname`,`email`, `id`, `message`,`reason`,`tstamp`)
    VALUES (_firstname, _lastname, _email, sha2(uuid(),224), _message,_reason,_now);
  SELECT _cksum AS id;
END$

-- =======================================================================
-- Register visitor request => shall deprecate register_touch_request
-- =======================================================================
DROP PROCEDURE IF EXISTS `store_request`$
CREATE PROCEDURE `store_request`(
  IN _firstname VARCHAR(255),
  IN _lastname VARCHAR(255),
  IN _email VARCHAR(255),
  IN _message TEXT,
  IN _reason VARCHAR(16)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _cksum VARCHAR(255);

  SELECT UNIX_TIMESTAMP() into _now;
  SELECT sha2(uuid(),224) INTO _cksum;

  INSERT INTO
    request (`firstname`,`lastname`,`email`, `id`, `message`,`reason`,`tstamp`)
    VALUES (_firstname, _lastname, _email, _cksum, _message,_reason,_now);

  SELECT *, message AS content, id as `key`  FROM request WHERE id = _cksum;
  -- SELECT _message AS content, _cksum AS `key`;
END$

-- =======================================================================
-- Register visitor request => shall deprecate register_touch_request & store_request
-- =======================================================================
DROP PROCEDURE IF EXISTS `log_request`$
CREATE PROCEDURE `log_request`(
  IN _firstname VARCHAR(255),
  IN _lastname VARCHAR(255),
  IN _email VARCHAR(255),
  IN _ident VARCHAR(255),
  IN _message TEXT,
  IN _reason VARCHAR(16)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _cksum VARCHAR(255);

  SELECT UNIX_TIMESTAMP() into _now;
  SELECT sha2(uuid(),224) INTO _cksum;

  INSERT INTO
    request (`firstname`,`lastname`,`email`, `id`, `message`,`reason`,`ident`,`tstamp`)
    VALUES (_firstname, _lastname, _email, _cksum, _message,_reason,_ident,_now);

  SELECT * FROM request WHERE id = _cksum;
END$

-- =======================================================================
-- Log signon
-- =======================================================================
DROP PROCEDURE IF EXISTS `log_signon`$
CREATE PROCEDURE `log_signon`(
  IN _firstname VARCHAR(255),
  IN _lastname VARCHAR(255),
  IN _email VARCHAR(500),
  IN _ident VARCHAR(80),
  IN _fingerprint VARCHAR(255),
  IN _ip VARCHAR(40),
  IN _referer VARCHAR(500)
)
BEGIN

  DECLARE _now INT(11) DEFAULT 0;
  DECLARE _key VARCHAR(255);

  SELECT UNIX_TIMESTAMP() into _now;
  SELECT sha2(uuid(),224) INTO _key;

  DELETE FROM signon WHERE email=_email;
  INSERT INTO
    signon VALUES(_firstname, _lastname, _email, _ident, _fingerprint, _key, _ip, _referer, _now);

  SELECT * FROM signon WHERE `key` = _key;
END$


DELIMITER ;

-- #####################
