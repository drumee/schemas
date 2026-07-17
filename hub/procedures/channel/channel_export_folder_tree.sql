DELIMITER $

-- =========================================================
-- channel_export_folder_tree
-- Folder subtree for chat export, rooted at _root_nid.
-- Chat export groups messages into one section per folder
-- (messages carry their folder in metadata._scope_nid), so the
-- export needs the list of folders under the exported folder.
--
-- _root_nid: the folder the export modal was opened in. NULL /
--   '' / '0' resolves to the hub root node (parent_id='0').
-- _hub_id: used only to resolve the display name of the hub
--   root, whose media row has an empty user_filename — the
--   name lives in yp.hub (name, falling back to hubname).
--
-- System folders (__chat__, __trash__, __upload__) never host
-- user chat and are pruned together with their subtrees.
-- READ-ONLY.
-- =========================================================
DROP PROCEDURE IF EXISTS `channel_export_folder_tree`$
CREATE PROCEDURE `channel_export_folder_tree`(
  IN _hub_id   VARCHAR(16),
  IN _root_nid VARCHAR(16)
)
BEGIN
  DECLARE _root VARCHAR(16) DEFAULT NULL;

  IF _root_nid IS NOT NULL AND _root_nid <> '' AND _root_nid <> '0' THEN
    SELECT id INTO _root FROM media WHERE id = _root_nid LIMIT 1;
  END IF;
  IF _root IS NULL THEN
    SELECT id INTO _root FROM media WHERE parent_id = '0' LIMIT 1;
  END IF;

  WITH RECURSIVE subtree AS (
    SELECT m.id, m.parent_id, m.user_filename, 0 AS depth
    FROM media m
    WHERE m.id = _root
    UNION ALL
    SELECT c.id, c.parent_id, c.user_filename, s.depth + 1
    FROM media c
    INNER JOIN subtree s ON c.parent_id = s.id
    WHERE c.mimetype = 'folder'
      AND c.status = 'active'
      AND c.user_filename NOT IN ('__chat__', '__trash__', '__upload__')
  )
  SELECT
    s.id,
    s.parent_id,
    s.depth,
    CASE
      WHEN s.depth = 0 AND (s.user_filename IS NULL OR s.user_filename = '')
        THEN (
          SELECT COALESCE(NULLIF(h.name, ''), NULLIF(h.hubname, ''), _hub_id)
          FROM yp.hub h WHERE h.id = _hub_id LIMIT 1
        )
      ELSE s.user_filename
    END AS name
  FROM subtree s
  ORDER BY s.depth ASC, s.user_filename ASC;
END $

DELIMITER ;
