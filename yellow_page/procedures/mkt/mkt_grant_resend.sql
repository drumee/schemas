DELIMITER $

-- =========================================================
-- mkt_grant_resend
-- "Send me that offer again." Re-mints the grant an address already holds.
--
-- A THIN WRAPPER OVER mkt_grant_issue, deliberately: every limit, the token
-- rotation and the unique key all live there, so there is exactly one piece of
-- code that can create or refresh a grant. A resend path with its own INSERT
-- would be a second way to make a row, and the invariant this feature rests on
-- is that there is only one.
--
-- IT READS THE CODE OFF THE EXISTING ROW rather than taking it as a parameter.
-- The caller is a signed-in user pressing "get a new link"; they must not be
-- able to name which coupon they are re-issued, or the button becomes a way to
-- request any code in the table.
--
-- CAMPAIGN IS OPTIONAL: '' resolves to the newest grant the address holds.
--
-- Refuses GRANT_NOT_FOUND when the address was never mailed this campaign.
-- There is nothing to re-send, and minting one here would let anyone with an
-- account grant themselves a campaign they were not part of -- which is the
-- exact opposite of the feature.
--
-- The remaining refusals (GRANT_REVOKED, RESEND_LIMIT, RESEND_COOLDOWN) come
-- straight back from mkt_grant_issue.
-- =========================================================
DROP PROCEDURE IF EXISTS `mkt_grant_resend`$
CREATE PROCEDURE `mkt_grant_resend`(
  IN _campaign     VARCHAR(64),
  IN _email        VARCHAR(255),
  IN _uid          VARCHAR(16),
  IN _ttl_sec      INT,
  IN _max_sends    INT,
  IN _cooldown_sec INT
)
proc: BEGIN
  DECLARE _code VARCHAR(64);
  DECLARE _single TINYINT;
  DECLARE _status VARCHAR(16);
  DECLARE _camp VARCHAR(64);
  DECLARE _em VARCHAR(255);

  SET _camp = TRIM(IFNULL(_campaign, ''));
  SET _em = LOWER(TRIM(IFNULL(_email, '')));

  IF _em = '' THEN
    SELECT 'ARGS_INVALID' AS error;
    LEAVE proc;
  END IF;

  -- AN EMPTY CAMPAIGN MEANS "the newest one this address holds", and that is
  -- the normal call. The person pressing "send me a new link" is looking at a
  -- refusal, not at a campaign name — and the client must not be the thing
  -- that names which offer to re-issue, or the button becomes a way to ask for
  -- any campaign in the table. Newest by issue time, non-revoked.
  IF _camp = '' THEN
    SELECT campaign INTO _camp
      FROM mkt_mail_grant
     WHERE email = _em AND status <> 'revoked'
     ORDER BY issued_at DESC, id DESC
     LIMIT 1;
    IF _camp IS NULL THEN
      SELECT 'GRANT_NOT_FOUND' AS error;
      LEAVE proc;
    END IF;
  END IF;

  SELECT code, single_use, status
    INTO _code, _single, _status
    FROM mkt_mail_grant
   WHERE campaign = _camp AND email = _em
   LIMIT 1;

  IF _code IS NULL THEN
    SELECT 'GRANT_NOT_FOUND' AS error;
    LEAVE proc;
  END IF;

  -- Answered here as well as in issue, so the refusal does not depend on the
  -- order of issue's own guards.
  IF _status = 'revoked' THEN
    SELECT 'GRANT_REVOKED' AS error;
    LEAVE proc;
  END IF;

  -- single_use is carried forward, not re-defaulted: a campaign that opted out
  -- of single-use must not silently opt back in when somebody asks for a new
  -- link.
  CALL mkt_grant_issue(_camp, _code, _em, _uid, _ttl_sec, _single,
                       _max_sends, _cooldown_sec);
END $

DELIMITER ;
