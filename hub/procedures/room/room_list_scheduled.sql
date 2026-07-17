
DELIMITER $

-- ==============================================================
-- room_list_scheduled
--
-- List the hub's scheduled meetings (media nodes with category
-- 'schedule') whose time window overlaps [_stime, _etime].
--
-- Meeting time is UNIX-epoch seconds stored in the node metadata.
-- NOTE: `metadata.content` is a STRINGIFIED JSON object (double
-- encoded by room.book/update), so we must extract `$.content`,
-- JSON_UNQUOTE it back into JSON text, then read `$.stime`/`$.etime`
-- from that — a plain `$.content.stime` path yields NULL.
--
-- Passing NULL for either bound returns every scheduled meeting.
-- Recurring meetings (recur.freq set) always come back so the client
-- can expand occurrences and filter to the visible window.
--
-- Overlap test: meeting [s, e] intersects window [f, t] iff
--   s <= t AND COALESCE(e, s) >= f
-- ==============================================================
DROP PROCEDURE IF EXISTS `room_list_scheduled`$
CREATE PROCEDURE `room_list_scheduled`(
  IN _stime INT(11),
  IN _etime INT(11)
)
BEGIN
  SELECT
    m.id,
    m.user_filename AS filename,
    m.owner_id,
    m.category,
    m.extension,
    m.mimetype,
    m.publish_time,
    m.metadata,
    CAST(JSON_VALUE(JSON_UNQUOTE(JSON_EXTRACT(m.metadata, '$.content')), '$.stime') AS UNSIGNED) AS stime,
    CAST(JSON_VALUE(JSON_UNQUOTE(JSON_EXTRACT(m.metadata, '$.content')), '$.etime') AS UNSIGNED) AS etime
  FROM media m
  WHERE m.category = 'schedule'
    AND m.status = 'active'
    AND (
      _stime IS NULL OR _etime IS NULL
      OR JSON_VALUE(JSON_UNQUOTE(JSON_EXTRACT(m.metadata, '$.content')), '$.recur.freq') IS NOT NULL
      OR (
        CAST(JSON_VALUE(JSON_UNQUOTE(JSON_EXTRACT(m.metadata, '$.content')), '$.stime') AS UNSIGNED) <= _etime
        AND COALESCE(
              CAST(JSON_VALUE(JSON_UNQUOTE(JSON_EXTRACT(m.metadata, '$.content')), '$.etime') AS UNSIGNED),
              CAST(JSON_VALUE(JSON_UNQUOTE(JSON_EXTRACT(m.metadata, '$.content')), '$.stime') AS UNSIGNED)
            ) >= _stime
      )
    )
  ORDER BY stime ASC;
END$

DELIMITER ;
