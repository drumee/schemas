DELIMITER $
DROP PROCEDURE IF EXISTS `meeting_schedule_range`$
-- Meetings visible to one user whose time window overlaps [_from, _to] (both
-- UNIX-epoch seconds). Feeds the Personal Calendar's aggregated read
-- (calendar.list).
--
-- This index already exists for the reminder worker, which is exactly why the
-- calendar reads it: one indexed query here replaces a JSON scan of every
-- per-hub `media` table. The worker's own procs (…_due / …_upcoming) filter on
-- the fired flags and cannot be reused for a calendar window.
--
-- Visibility is organizer-OR-attendee, deliberately not "every meeting in every
-- workspace I belong to": the index models participation, and a personal
-- calendar showing every colleague's meeting would be unusable.
--
-- `attendees` is utf8mb4_bin, so it is CONVERTed before the JSON search — a raw
-- JSON_CONTAINS against an ascii uid literal is an illegal mix of collations.
CREATE PROCEDURE `meeting_schedule_range`(
  IN _uid VARCHAR(16),
  IN _from INT(11) UNSIGNED,
  IN _to INT(11) UNSIGNED
)
BEGIN
  SELECT
    id,
    hub_id,
    nid,
    stime,
    etime,
    created_by,
    title,
    message,
    attendees,
    recur
  FROM meeting_schedule
  WHERE stime <= _to
    -- A meeting with no recorded end still occupies its start instant.
    AND IF(etime > 0, etime, stime) >= _from
    AND (
      created_by = _uid
      OR JSON_CONTAINS(
           CONVERT(attendees USING utf8mb4),
           JSON_QUOTE(CONVERT(_uid USING utf8mb4))
         )
    )
  ORDER BY stime ASC;
END$
DELIMITER ;
