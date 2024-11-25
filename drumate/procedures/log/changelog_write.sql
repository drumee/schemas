DELIMITER $

DROP PROCEDURE IF EXISTS `changelog_write`$
-- CREATE PROCEDURE `changelog_write`(
--   IN _event VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci,
--   IN _src JSON,
--   IN _dest JSON
-- )
-- BEGIN
--   INSERT INTO changelog VALUES(
--     null, 
--     unix_timestamp(), 
--     _event,
--     _src,
--     _dest
--   );
--   `id` syncId,
--   `timestamp`,
--   `service`,
--   `src`,
--   `dest`
--   FROM changelog WHERE id=max(id);
-- END$

DELIMITER ;
