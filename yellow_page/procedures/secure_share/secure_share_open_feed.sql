DELIMITER $

DROP PROCEDURE IF EXISTS `secure_share_open_feed`$
CREATE PROCEDURE `secure_share_open_feed`(
  IN _creator_id VARCHAR(16) CHARACTER SET ascii,
  IN _unread_only TINYINT(1)
)
BEGIN
  -- Share-open events for the creator's notify-on-open shares, deduped to the
  -- latest open per (token, recipient). is_read = the creator has already seen
  -- this open at-or-after its latest activity (creator_seen_at >= last_seen_at);
  -- a recipient re-opening (newer last_seen_at) flips it back to unread, like the
  -- read-pointer model of the activity feed. _unread_only mirrors the feed toggle:
  -- 1 => unseen only, 0 => all. Replaces the old 7-day rolling list with a
  -- persistent, toggle-aware read model. The server enriches node_name and merges
  -- these rows into activity.get_feed so they render as ordinary feed events.
  SELECT
    MAX(e.sys_id)        AS id,
    e.token_id,
    e.hub_id,
    e.node_id,
    e.recipient_email,
    MAX(e.actor_id)      AS actor_id,
    MAX(e.last_seen_at)  AS last_seen_at,
    IF(MAX(IFNULL(e.creator_seen_at, 0)) >= MAX(e.last_seen_at), 1, 0) AS is_read
  FROM secure_share_access_event e
  JOIN secure_share_token t ON t.id = e.token_id
  WHERE t.creator_id = _creator_id
    AND t.notify_on_open != 0
    AND (e.actor_id IS NULL OR e.actor_id != _creator_id)
  GROUP BY e.token_id, e.hub_id, e.node_id, e.recipient_email
  HAVING (_unread_only = 0 OR is_read = 0)
  ORDER BY last_seen_at DESC
  LIMIT 50;
END$

DELIMITER ;
