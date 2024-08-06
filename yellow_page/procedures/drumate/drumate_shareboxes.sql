DELIMITER $


-- =========================================================
-- Checks whether drumate with given id/email exist or not.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_shareboxes`$
CREATE PROCEDURE `drumate_shareboxes`(
  IN _id          VARCHAR(500)
)
BEGIN
  DECLARE _db_name VARCHAR(30);
  DECLARE _inbound_id VARCHAR(16);
  DECLARE _outbound_id VARCHAR(16);
  DECLARE _dp TINYINT(4);
  DECLARE _drumate_id VARCHAR(16);
  DECLARE _drumate_db VARCHAR(160);
  DECLARE _sb_id VARCHAR(16);

  SELECT e.id AS hub_id, 
    e.home_id, 
    h.hubname, 
    h.hubname AS filename, 
    v.fqdn AS vhost, 
    JSON_VALUE(`settings`, "$.default_privilege") AS default_privilege
    FROM yp.hub h 
      INNER JOIN yp.entity e USING(id) 
      INNER JOIN yp.vhost v USING(id) 
    WHERE area = 'dmz' and owner_id=_id AND `serial`=0;

END$

DELIMITER ;
