DELIMITER $

-- =========================================================
-- member_title_list
-- =========================================================
-- Titles for the uids on one page of the Member tab, in one round trip.
-- _uids is a JSON array of uid strings (the service passes the page's uids).
-- Only titled uids come back; the caller treats a missing uid as no title.
-- Invalid JSON answers with zero rows instead of raising, because a broken
-- title read must never take the member list down with it.
--
-- Scans the domain's rows (PRIMARY KEY prefix) and filters with JSON_CONTAINS:
-- a domain holds at most one row per member, so this stays small without a
-- JSON_TABLE join and its collation pitfalls.
DROP PROCEDURE IF EXISTS `member_title_list`$
CREATE PROCEDURE `member_title_list`(
  IN _domain_id INT UNSIGNED,
  IN _uids      LONGTEXT
)
proc: BEGIN
  IF _uids IS NULL OR JSON_VALID(_uids) = 0 THEN
    SELECT uid, title FROM member_title WHERE 1 = 0;
    LEAVE proc;
  END IF;

  SELECT t.uid, t.title
    FROM member_title t
   WHERE t.domain_id = _domain_id
     AND JSON_CONTAINS(_uids, JSON_QUOTE(t.uid));
END$

DELIMITER ;
