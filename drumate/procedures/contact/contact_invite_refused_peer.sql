DELIMITER $

DROP PROCEDURE IF EXISTS `contact_invite_refused_peer`$
CREATE PROCEDURE `contact_invite_refused_peer`(
  IN _refuser_id VARCHAR(16)
)
BEGIN
  DECLARE _contact_id VARCHAR(16);

  SELECT id FROM contact
  WHERE entity = _refuser_id AND status IN ('sent', 'invitation')
  LIMIT 1
  INTO _contact_id;

  IF _contact_id IS NOT NULL THEN
    DELETE FROM contact_email   WHERE contact_id = _contact_id;
    DELETE FROM contact_phone   WHERE contact_id = _contact_id;
    DELETE FROM contact_address WHERE contact_id = _contact_id;
    DELETE FROM map_tag         WHERE id = _contact_id;
    CALL contact_block_delete(_contact_id);
    DELETE FROM contact         WHERE id = _contact_id;
  END IF;
END$

DELIMITER ;
