DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_delete_activity`$
CREATE PROCEDURE `mfs_delete_activity`(
  IN _user_id VARCHAR(16),
  IN _changelog_id INT(11)
)
BEGIN
  -- The trash button, as distinct from reading. mfs_dismiss_activity keeps
  -- meaning "mark read" and is deliberately NOT touched: changing its arity
  -- would break every production caller at once, MariaDB having no default
  -- parameters. This is a new name, so it has no existing callers and cannot
  -- break anything.
  --
  -- INSERT ... ON DUPLICATE KEY covers both entry points with one statement:
  -- trashing a row the user had already read (a mfs_dismissed row exists, so
  -- flip its flag) and trashing one they never opened (no row yet, so create
  -- it already deleted). Splitting these into an IF would add a branch that
  -- the primary key (changelog_id, user_id) already resolves.
  --
  -- deleted = 1 implies read: activity_get_feed_all treats the presence of the
  -- row as is_read, and a deleted row is filtered out entirely, so a trashed
  -- notification can never keep counting toward the unread badge.
  --
  -- Scoping is structural rather than checked: the table is keyed by user_id
  -- and this writes _user_id, so a caller can only ever mark their own copy.
  INSERT INTO mfs_dismissed (changelog_id, user_id, mtime, deleted)
  VALUES (_changelog_id, _user_id, UNIX_TIMESTAMP(), 1)
  ON DUPLICATE KEY UPDATE
    deleted = 1,
    mtime   = UNIX_TIMESTAMP();

  SELECT 'ok' AS status, _changelog_id AS changelog_id, 1 AS deleted;
END$

DELIMITER ;
