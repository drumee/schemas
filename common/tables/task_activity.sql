-- Folder-scoped task activity feed. One row per logged task event, surfaced by
-- the Project Health view's "Recent activity" panel via task_activity_list.
-- `nid` is denormalized from the task at log time so the feed can be queried
-- per-folder cheaply and survives the task being deleted.
CREATE TABLE IF NOT EXISTS task_activity (
  sys_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  task_id varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  nid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci DEFAULT NULL,
  actor_uid varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  action enum('create','update','status','assignee','reporter','link_file','comment','complete') NOT NULL,
  meta text DEFAULT NULL,
  ctime int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (sys_id),
  KEY idx_nid_ctime (nid, ctime),
  KEY idx_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
