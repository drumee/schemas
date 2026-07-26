DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_deny_email`$
CREATE PROCEDURE `secure_share_deny_email`(
  IN _token      VARCHAR(80),
  IN _creator_id VARCHAR(16) CHARACTER SET ascii,
  IN _email      VARCHAR(512)
)
BEGIN
  -- Cut ONE recipient off a link while the link keeps working for everyone else.
  -- Denying is additive and reversible: the sender's allowed_emails is left exactly
  -- as they wrote it, and the gate refuses a denied address whichever way the
  -- allow rule was expressed (named address, @domain, or "any email"). Emptying
  -- allowed_emails instead would have been destructive AND unsafe — the gate reads
  -- an empty allow-list as "no restriction", so removing the last recipient would
  -- have turned a restricted link into an open one.
  DECLARE _mail VARCHAR(512);

  SET _mail = LOWER(TRIM(_email));

  IF _mail IS NULL OR _mail = '' THEN
    SELECT 0 AS denied;
  ELSE
    -- Scoped to the creator: an empty result set tells the caller the deny did not
    -- happen (unknown token, or not theirs). Idempotent — denying an address that
    -- is already denied leaves the list unchanged.
    UPDATE `secure_share_token`
    SET    denied_emails = IF(
             denied_emails IS NULL,
             JSON_ARRAY(_mail),
             IF(JSON_CONTAINS(denied_emails, JSON_QUOTE(_mail)),
                denied_emails,
                JSON_ARRAY_APPEND(denied_emails, '$', _mail))
           )
    WHERE  id         = _token
      AND  creator_id = _creator_id;

    SELECT
      s.id      AS token,
      s.hub_id,
      s.node_id,
      s.denied_emails,
      JSON_CONTAINS(IFNULL(s.denied_emails, JSON_ARRAY()), JSON_QUOTE(_mail)) AS denied
    FROM `secure_share_token` s
    WHERE  s.id         = _token
      AND  s.creator_id = _creator_id;
  END IF;
END$

DELIMITER ;
