DELIMITER $
DROP PROCEDURE IF EXISTS `update_transfer_session`$
CREATE PROCEDURE `update_transfer_session`(
  IN _nid  varchar(16),
  IN _session  varchar(64)  
)
BEGIN
 UPDATE media SET metadata=JSON_MERGE(
      IFNULL(metadata, '{}'), 
      JSON_OBJECT('session', JSON_OBJECT(_session, UNIX_TIMESTAMP()))
    )
    WHERE id=_nid;
END $

DELIMITER ;