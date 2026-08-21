CREATE TABLE IF NOT EXISTS task (
  id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  title varchar(500) NOT NULL,
  description text DEFAULT NULL,
  -- Column key: one of the four built-ins (todo|in_progress|to_review|complete)
  -- or a custom task_column.id. varchar (not enum) so user-defined columns work.
  status varchar(32) NOT NULL DEFAULT 'todo',
  priority enum('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  due_date date DEFAULT NULL,
  -- Optional range start. NULL = single-date task (Duration toggle OFF);
  -- when set, the task spans start_date .. due_date (Duration toggle ON).
  start_date date DEFAULT NULL,
  -- Write-once provenance: who actually created the task (task_create only).
  -- Never updated — the detail panel shows task.ctime beside the reporter, so a
  -- mutable created_by would make that timestamp lie. See reporter_uid below.
  created_by varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  -- Editable Reporter: who the task is reported BY, which the creator may
  -- reassign (like an assignee). NULL = "same as created_by", which is how every
  -- row predating alter_task_add_reporter.sql reads — the SPs COALESCE it, so an
  -- unpatched database keeps rendering the creator and the field is simply
  -- read-only there.
  reporter_uid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- Legacy single-assignee column. Superseded by the task_assignee join table
  -- (multi-assignee). Kept for backward compat; no longer written by the SPs.
  assignee_uid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- Folder/node scope: media node id of the folder the task belongs to.
  -- NULL = legacy / workspace-level task (surfaces at the workspace root view).
  nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  -- Subtask link: id of the parent task, or NULL for a normal top-level task.
  -- Nesting is ONE level only — a row with parent_task_id set can never itself
  -- be a parent. Enforced in the service layer (task.create), since SQL cannot
  -- express it without a trigger. A subtask always shares its parent's nid, so
  -- it lives on the same board and inherits that folder's ACL.
  parent_task_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  rank int(11) NOT NULL DEFAULT 0,
  ctime int(11) NOT NULL DEFAULT 0,
  mtime int(11) NOT NULL DEFAULT 0,
  -- Unix timestamp the task most recently entered the 'complete' status.
  -- 0 = never completed (or moved back out of complete). Drives the Project
  -- Health "completed in last 7 days" and average cycle-time stats.
  completed_at int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_status (status),
  KEY idx_priority (priority),
  KEY idx_created_by (created_by),
  KEY idx_reporter_uid (reporter_uid),
  KEY idx_assignee_uid (assignee_uid),
  KEY idx_nid (nid),
  KEY idx_parent_task_id (parent_task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
