DELIMITER $

DROP PROCEDURE IF EXISTS `activity_get_deleted_ids`$
CREATE PROCEDURE `activity_get_deleted_ids`(
  IN _user_id VARCHAR(16)
)
BEGIN
  -- Rows the user removed with the trash button, so the caller can drop them
  -- from the feed.
  --
  -- WHY THIS IS A SEPARATE PROCEDURE INSTEAD OF TWO WHERE CLAUSES INSIDE
  -- activity_get_feed_all. That procedure serves the entire notification feed,
  -- and it would have to reference mfs_dismissed.deleted and
  -- contact_activity.deleted_at -- columns added by the patches that ship
  -- alongside this. On any database where those patches had not landed yet the
  -- procedure would raise ER_BAD_FIELD_ERROR, and lib/mariadb.js _handleError
  -- does not re-throw: it logs a warning, rolls back, ends the connection and
  -- returns undefined. The service turns that into an empty array, so the user
  -- would get a COMPLETELY BLANK notification panel with no error surfaced
  -- anywhere. Keeping the dependency in a separate, optional call inverts the
  -- failure: if this procedure is missing the caller filters nothing and the
  -- worst case is that a deleted row reappears -- visible, harmless and
  -- self-evidently wrong, rather than silent and total.
  --
  -- activity_get_feed_all is therefore left byte-for-byte unchanged.
  --
  -- Not paginated on purpose. The caller needs the WHOLE set to filter any
  -- page, and the set only grows when a user presses trash, so it is naturally
  -- small; a limit here would let old deleted rows silently return once a user
  -- passed it, which is the one outcome this feature must never produce.
  SELECT 'mfs' AS kind, changelog_id AS id
    FROM mfs_dismissed
   WHERE user_id = _user_id
     AND deleted = 1

  UNION ALL

  SELECT 'contact' AS kind, id AS id
    FROM yp.contact_activity
   WHERE target_uid = _user_id
     AND deleted_at IS NOT NULL

  UNION ALL

  -- Share-open notifications. These have no single row id the caller can match
  -- on: secure_share_open_feed GROUPs the events and reports MAX(sys_id), a
  -- computed value this procedure would have to reproduce exactly to stay in
  -- step. The stable identity is the pair the feed row actually carries and the
  -- one secure_share_delete_open acts on -- (token_id, recipient_email) -- so
  -- that is what is returned, joined with '|'. IFNULL collapses an anonymous
  -- open's NULL recipient to '', matching both the NULLIF(...,'') the
  -- secure_share procedures use and the `recipient_email || ''` the caller
  -- builds; without it anonymous opens would never match.
  --
  -- HAVING counts the rows NOT yet deleted rather than testing any single row:
  -- deleting stamps the whole (token, recipient) group, but a LATER re-open
  -- inserts a fresh event with creator_deleted_at NULL, and that new activity
  -- must bring the notification back -- exactly as a newer last_seen_at flips
  -- is_read back to unread in secure_share_open_feed. Testing "any row deleted"
  -- would suppress it forever.
  SELECT 'share_open' AS kind,
         CONCAT(e.token_id, '|', IFNULL(e.recipient_email, '')) AS id
    FROM yp.secure_share_access_event e
    JOIN yp.secure_share_token t ON t.id = e.token_id
   WHERE t.creator_id = _user_id
   GROUP BY e.token_id, IFNULL(e.recipient_email, '')
  HAVING SUM(e.creator_deleted_at IS NULL) = 0;
END$

DELIMITER ;
