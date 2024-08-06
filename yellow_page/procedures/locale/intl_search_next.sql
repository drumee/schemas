DELIMITER $
DROP PROCEDURE IF EXISTS `intl_search_next`$
CREATE PROCEDURE `intl_search_next`(
  IN _arg VARCHAR(128),
  IN _cat VARCHAR(128),
  IN _page INT(4)
)
BEGIN
  DECLARE _range bigint;
  DECLARE _offset bigint;
  CALL pageToLimits(_page, _offset, _range);

  IF LENGTH(_arg) < 3 THEN
    SET @arg = CONCAT(TRIM(_arg), '%');
  ELSE
    SET @arg = CONCAT('%', TRIM(_arg), '%');
  END IF;

  DROP TABLE IF EXISTS __tmp_search;
  CREATE TEMPORARY TABLE __tmp_search (
    `sys_id` int(11) unsigned,
    `key_code` varchar(40) NOT NULL,
    `category` varchar(40),
    `lng` varchar(20) NOT NULL,
    `des` text NOT NULL
  );

  INSERT INTO __tmp_search SELECT * FROM languages 
    WHERE category=_cat AND key_code LIKE @arg OR `des` LIKE @arg
    ORDER BY `key_code` ASC LIMIT _offset, _range;

  SELECT 
    l.*, 
    l.sys_id id 
  FROM __tmp_search t 
    LEFT JOIN languages l ON t.key_code=l.key_code 
  WHERE l.category=_cat ORDER BY `key_code` ASC;
END $



DELIMITER ;
