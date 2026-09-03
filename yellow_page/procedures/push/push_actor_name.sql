DELIMITER $

-- =========================================================
-- push_actor_name
--
-- Display name for the account that triggered a mobile push, for use as the
-- notification title. Built from the given and family name only: the generated
-- `drumate.fullname` column falls back to the account email once both are
-- empty, and an email address must never reach a push provider or a locked
-- screen. An account with neither name returns an empty string, which the
-- caller treats as "no identity to show" and degrades to a generic banner.
-- =========================================================
DROP PROCEDURE IF EXISTS `push_actor_name`$
CREATE PROCEDURE `push_actor_name`(
  IN _uid VARCHAR(16)
)
BEGIN
  SELECT IFNULL(
    TRIM(CONCAT_WS(
      ' ',
      NULLIF(TRIM(IFNULL(firstname, '')), ''),
      NULLIF(TRIM(IFNULL(lastname, '')), '')
    )),
    ''
  ) AS display_name
  FROM drumate
  WHERE id = _uid
  LIMIT 1;
END$

DELIMITER ;
