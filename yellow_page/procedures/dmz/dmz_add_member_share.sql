DELIMITER $

DROP PROCEDURE IF EXISTS `dmz_add_member_share_next`$
DROP PROCEDURE IF EXISTS `dmz_add_member_share`$
-- CREATE PROCEDURE `dmz_add_member_share_next`(
--   IN _email         VARCHAR(500),
--   IN _name         VARCHAR(500)  
-- )
-- BEGIN
--   DECLARE _id  VARCHAR(16) ; 
--   SELECT yp.uniqueId() INTO _id;
--   SELECT id FROM member_share WHERE email = _email INTO _id; 
--   REPLACE INTO member_share (sys_id, id, email, `name`) SELECT  NULL, _id, _email, _name;
--   SELECT * FROM member_share WHERE id = _id;
-- END$

DELIMITER ;