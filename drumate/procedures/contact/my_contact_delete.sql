DELIMITER $
DROP PROCEDURE IF EXISTS `my_contact_delete`$
CREATE PROCEDURE `my_contact_delete`(
  IN  _contact_id VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  DECLARE _id          VARCHAR(255) CHARACTER SET ascii;
  DECLARE _drumate_db  VARCHAR(255);
  DECLARE _email       VARCHAR(1000);
  DECLARE _his_id      VARCHAR(255) CHARACTER SET ascii;

  -- Other party: uid when the contact is a drumate, else entity (email).
  SELECT IFNULL(uid, entity) FROM contact
   WHERE (id = _contact_id OR uid = _contact_id) INTO _his_id;
  SELECT db_name FROM yp.entity WHERE id = _his_id INTO _drumate_db;

  -- Caller (owner of the current contact_book DB).
  SELECT id FROM yp.entity WHERE db_name = DATABASE() INTO _id;
  SELECT email FROM yp.drumate WHERE id = _id INTO _email;

  -- ── Mirror hard-delete on the other party's DB ─────────────────────
  -- Deleting a contact on one side removes the relationship on BOTH,
  -- for every status (active, informed, invitation, received, sent,
  -- memory). The other party's sub-records (emails, phones, addresses,
  -- tag mappings, blocks) are removed with the row.
  IF _drumate_db IS NOT NULL THEN
    SELECT NULL INTO @_his_contact_id;
    SET @st = CONCAT(
      'SELECT id FROM ', _drumate_db, '.contact ',
      'WHERE uid = ? OR entity = ? OR uid = ? OR entity = ? ',
      'INTO @_his_contact_id');
    PREPARE stamt FROM @st;
    EXECUTE stamt USING _id, _id, _email, _email;
    DEALLOCATE PREPARE stamt;

    IF @_his_contact_id IS NOT NULL THEN
      SET @st = CONCAT('DELETE FROM ', _drumate_db, '.contact_email   WHERE contact_id = ?');
      PREPARE stamt FROM @st; EXECUTE stamt USING @_his_contact_id; DEALLOCATE PREPARE stamt;

      SET @st = CONCAT('DELETE FROM ', _drumate_db, '.contact_phone   WHERE contact_id = ?');
      PREPARE stamt FROM @st; EXECUTE stamt USING @_his_contact_id; DEALLOCATE PREPARE stamt;

      SET @st = CONCAT('DELETE FROM ', _drumate_db, '.contact_address WHERE contact_id = ?');
      PREPARE stamt FROM @st; EXECUTE stamt USING @_his_contact_id; DEALLOCATE PREPARE stamt;

      SET @st = CONCAT('DELETE FROM ', _drumate_db, '.map_tag         WHERE id = ?');
      PREPARE stamt FROM @st; EXECUTE stamt USING @_his_contact_id; DEALLOCATE PREPARE stamt;

      SET @st = CONCAT('DELETE FROM ', _drumate_db, '.contact         WHERE id = ?');
      PREPARE stamt FROM @st; EXECUTE stamt USING @_his_contact_id; DEALLOCATE PREPARE stamt;

      -- contact_block_delete only touches yp.contact_block, so the
      -- caller-side copy of the proc clears the other party's blocks too.
      CALL contact_block_delete(@_his_contact_id);
    END IF;
  END IF;

  -- ── Hard-delete on the caller's side ───────────────────────────────
  DELETE FROM map_tag         WHERE id = _contact_id;
  DELETE FROM contact         WHERE id = _contact_id;
  DELETE FROM contact_email   WHERE contact_id = _contact_id;
  DELETE FROM contact_phone   WHERE contact_id = _contact_id;
  DELETE FROM contact_address WHERE contact_id = _contact_id;
  CALL contact_block_delete(_contact_id);

  -- Return the other party id so `delete_contact` can notify their sockets.
  SELECT _his_id AS his_id;
END$
DELIMITER ;
