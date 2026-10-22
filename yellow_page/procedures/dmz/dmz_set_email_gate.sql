DELIMITER $

-- =========================================================
-- dmz_set_email_gate
-- =========================================================
-- Set a dmz link's email gate: _require_email (0/1) asks the viewer for an
-- email at the gate; _allowed_emails (a JSON array of addresses and
-- "@domain" entries, or NULL) restricts which ones pass. Called by
-- room.public_link after every dmz_grant_next, whose REPLACE resets both
-- columns, so the gate always matches the latest settings.
DROP PROCEDURE IF EXISTS `dmz_set_email_gate`$
CREATE PROCEDURE `dmz_set_email_gate`(
  IN _token VARCHAR(64),
  IN _require_email TINYINT,
  IN _allowed_emails JSON
)
BEGIN
  UPDATE dmz_token
    SET require_email = IF(IFNULL(_require_email, 0) = 1, 1, 0),
        allowed_emails = IF(JSON_LENGTH(IFNULL(_allowed_emails, '[]')) > 0, _allowed_emails, NULL)
    WHERE id = _token;
  SELECT id token, require_email, allowed_emails FROM dmz_token WHERE id = _token;
END $

DELIMITER ;
