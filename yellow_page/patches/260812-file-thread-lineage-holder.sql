-- =========================================================
-- file_thread_lineage: track where the FILE went, separately from
-- where the THREAD lives.
--
-- Until now current_hub_id/current_file_nid carried two meanings at once,
-- because trash never moved the file: the thread's position and the file's
-- position were the same row. Cross-workspace move splits them — the thread
-- stays, the file leaves — so the file's location needs columns of its own.
--
--   current_*  = where the THREAD is       (changes only when the thread rebinds)
--   holder_*   = where the FILE is, NULL when the file is home
--
-- Keeping current_* stable is what lets the UNIQUE (current_hub_id,
-- current_file_nid) index stay correct: a thread created later on the moved
-- file, in the destination workspace, gets its own lineage row without
-- colliding with the one left behind.
--
-- state gains 'orphaned': a terminal value for "the file was permanently
-- deleted while away", distinct from 'unavailable' (still returnable) and
-- from 'failed' (which means a saga broke, a different thing entirely).
-- =========================================================

ALTER TABLE `file_thread_lineage`
  MODIFY COLUMN `state`
    enum('active','moving','unavailable','conflict','failed','orphaned')
    NOT NULL DEFAULT 'active';

ALTER TABLE `file_thread_lineage`
  ADD COLUMN IF NOT EXISTS `holder_hub_id`
    varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT 'Hub currently holding the file; NULL when the file is at its home hub'
    AFTER `current_thread_id`,
  ADD COLUMN IF NOT EXISTS `holder_file_nid`
    varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL
    COMMENT 'Node id of the file in the holding hub; NULL when the file is home'
    AFTER `holder_hub_id`,
  -- The media row is deleted when the file leaves, taking the name with it.
  -- Without a copy the thread would be listed as a raw node id — the folder
  -- would show "zzRLnid000000001" where it used to say "quarterly report".
  ADD COLUMN IF NOT EXISTS `file_name`
    varchar(255) DEFAULT NULL
    COMMENT 'Filename as it was when the file left, for display while it is away'
    AFTER `holder_file_nid`;

-- Resolving "which thread belongs to the file that just arrived here" is a
-- holder_* lookup on every cross-hub move.
--
-- No index is added on current_thread_id: nothing keys on it. Thread id is
-- not unique in this table — a failed move can leave a second row carrying
-- the same thread id and a dead current_file_nid — so every lookup goes
-- through current_file_nid or holder_*, both of which are already indexed.
ALTER TABLE `file_thread_lineage`
  ADD KEY IF NOT EXISTS `file_thread_lineage_holder_idx` (`holder_hub_id`, `holder_file_nid`);
