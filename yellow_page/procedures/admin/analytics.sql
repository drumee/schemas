DELIMITER $

DROP PROCEDURE IF EXISTS `analytics`$
CREATE PROCEDURE `analytics`(
)
BEGIN
  DECLARE _users_count INTEGER UNSIGNED;
  DECLARE _uploads_count INTEGER UNSIGNED;
  DECLARE _disk_usage BIGINT UNSIGNED;
  DECLARE _active_users INTEGER;
  DECLARE _avg_uploads DECIMAL(10,2);

  DECLARE _user_date VARCHAR(512);
  DECLARE _disk_date VARCHAR(512);

  SELECT count(*) users_number, FROM_UNIXTIME(max(ctime), '%Y/%m/%d : %H:%i') user_date 
    FROM drumate d INNER JOIN entity e USING(id) INTO _users_count, _user_date;

  SELECT count(*) uploads_count, FROM_UNIXTIME(max(timestamp), '%Y/%m/%d : %H:%i') disk_date 
    FROM  mfs_changelog WHERE EVENT='media.new' INTO _uploads_count, _disk_date;
  
  SELECT sum(size) disk_usage FROM disk_usage INTO _disk_usage;

  DROP TABLE IF EXISTS _uploads;
  CREATE TEMPORARY TABLE _uploads AS 
    SELECT count(*) files, uid FROM mfs_changelog WHERE event='media.new' GROUP BY uid;

  SELECT count(*) FROM _uploads INTO _active_users;
  SELECT avg(files) FROM _uploads INTO _avg_uploads;

  SELECT 
    _users_count users_count,
    _uploads_count uploads_count,
    _disk_usage disk_usage,
    _active_users active_users,
    _avg_uploads avg_uploads,
    _user_date user_date,
    _disk_date disk_date;
END$

DELIMITER ;

-- #####################
