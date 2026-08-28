DELIMITER $

-- =========================================================
-- mkt_grant_revoke
-- Kill one address's grant on one campaign. The admin stop button.
--
-- Terminal by design: mkt_grant_issue refuses to re-mint a revoked row, so a
-- resend cannot quietly undo this. Lifting it is a deliberate UPDATE by
-- someone with database access, which is the right amount of friction for
-- "this offer was obtained by someone it was not meant for".
--
-- Answers GRANT_NOT_FOUND rather than succeeding silently: revoking something
-- that was never issued means the caller has the wrong address or the wrong
-- campaign, and telling them so is more useful than a no-op that reads as done.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_grant_revoke`$
CREATE PROCEDURE `mkt_grant_revoke`(
  IN _campaign VARCHAR(64),
  IN _email    VARCHAR(255)
)
proc: BEGIN
  DECLARE _id INT UNSIGNED;
  DECLARE _now INT UNSIGNED;
  DECLARE _camp VARCHAR(64);
  DECLARE _em VARCHAR(255);

  SET _now = UNIX_TIMESTAMP();
  SET _camp = TRIM(IFNULL(_campaign, ''));
  SET _em = LOWER(TRIM(IFNULL(_email, '')));

  IF _camp = '' OR _em = '' THEN
    SELECT 'ARGS_INVALID' AS error;
    LEAVE proc;
  END IF;

  SELECT id INTO _id FROM mkt_mail_grant
   WHERE campaign = _camp AND email = _em LIMIT 1;
  IF _id IS NULL THEN
    SELECT 'GRANT_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;

  UPDATE mkt_mail_grant
     SET status = 'revoked', mtime = _now
   WHERE id = _id;

  SELECT id, campaign, code, email, status, send_count, claim_count
    FROM mkt_mail_grant WHERE id = _id;
END $

DELIMITER ;
