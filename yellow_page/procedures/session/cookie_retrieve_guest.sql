DELIMITER $

DROP PROCEDURE IF EXISTS `cookie_retrieve_guest`$
-- CREATE PROCEDURE `cookie_retrieve_guest`(
--   IN _key VARCHAR(512)
-- )
-- BEGIN
--   DECLARE _id VARCHAR(16);
--   DECLARE _hub_id VARCHAR(16);
--   DECLARE _dom_id INTEGER;
--   DECLARE _dom_name VARCHAR(50);
--   DECLARE _db_name VARCHAR(160);
--   DECLARE _email VARCHAR(512);
--   DECLARE _home_dir VARCHAR(512);
--   DECLARE _disk_usage float(16);
--   DECLARE _uid VARCHAR(16);

--   SELECT c.recipient_id, c.hub_id, 'guest', email FROM cookie_share c 
--     INNER JOIN member_share m ON m.id=c.recipient_id
--     WHERE c.recipient_id=_key AND is_verified 
--     LIMIT 1 INTO _uid, _hub_id, _email;

--   SELECT db_name, home_dir, d.id, d.name FROM entity e INNER JOIN domain d on e.dom_id=d.id 
--     WHERE id=_hub_id INTO _db_name, _home_dir, _dom_id, _dom_name;

  
--   SELECT
--     _hub_id AS id,
--     _hub_id as hub_id,
--     _email AS ident,
--     _db_name AS db_name,
--     _dom_name AS domain,
--     _dom_id AS domain_id,
--     _home_dir,
--     'guest' AS status,
--     _email AS fullname;
    
-- END$


DELIMITER ;