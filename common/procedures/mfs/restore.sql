DELIMITER $

DROP PROCEDURE IF EXISTS `mfs_restore`$

CREATE PROCEDURE `mfs_restore`(
  IN _id VARCHAR(16)
)
BEGIN
  DECLARE _category VARCHAR(40);
  DECLARE _old_node_path VARCHAR(6000);
  DECLARE _new_node_path VARCHAR(6000);
  DECLARE _parent_id VARCHAR(16);
  DECLARE _home_id VARCHAR(16);
  DECLARE _hub_id VARCHAR(16);
  DECLARE _total_filesize BIGINT DEFAULT 0;
  DECLARE _parent_exists INT DEFAULT 0;
  DECLARE _restored_filename VARCHAR(128);
  DECLARE _extension VARCHAR(100);

  -- Get home_id and hub_id first
  SELECT id INTO _home_id
  FROM media WHERE (parent_id IS NULL OR parent_id = '' OR parent_id = '0');

  SELECT id INTO _hub_id
  FROM yp.entity WHERE db_name = database();

  IF _id IS NULL OR _id = _home_id THEN
    SELECT 1 AS failed, 0 AS parent_missing, 'Could not restore root itself' AS message;
  ELSE
    -- Read from trash_media
    SELECT category, parent_id, user_filename, extension
    INTO _category, _parent_id, _restored_filename, _extension
    FROM trash_media WHERE id = _id;

    -- Check if original parent still exists
    SELECT COUNT(*) INTO _parent_exists
    FROM media WHERE id = _parent_id;

    IF _parent_exists = 0 THEN
      -- Original location is gone, FE must show location picker
      SELECT 0 AS failed, 1 AS parent_missing, _parent_id AS original_parent_id, _id AS nid;
    ELSE
      -- Resolve filename conflict at original location
      SET _restored_filename = unique_filename(_parent_id, _restored_filename, COALESCE(_extension, ''));

      START TRANSACTION;

      -- Capture old base path for folder-children lookup
      IF _category = 'folder' THEN
        SELECT CONCAT(parent_path, user_filename) INTO _old_node_path
        FROM trash_media WHERE id = _id;
      END IF;

      -- Restore root node with conflict-resolved filename
      INSERT INTO media (
        sys_id, id, origin_id, owner_id, host_id,
        file_path, user_filename, parent_id, parent_path,
        extension, mimetype, category, isalink, filesize,
        geometry, publish_time, upload_time,
        last_download, download_count, metadata, caption,
        status, approval, rank
      )
      SELECT
        sys_id, id, origin_id, owner_id, host_id,
        file_path, _restored_filename, parent_id, parent_path,
        extension, mimetype, category, isalink, filesize,
        geometry, publish_time, upload_time,
        last_download, download_count, metadata, caption,
        'active', approval, rank
      FROM trash_media WHERE id = _id;

      -- For folders: restore all children recursively
      -- No conflict check needed, children nest under the restored folder
      IF _category = 'folder' THEN
        INSERT INTO media (
          sys_id, id, origin_id, owner_id, host_id,
          file_path, user_filename, parent_id, parent_path,
          extension, mimetype, category, isalink, filesize,
          geometry, publish_time, upload_time,
          last_download, download_count, metadata, caption,
          status, approval, rank
        )
        SELECT
          sys_id, id, origin_id, owner_id, host_id,
          file_path, user_filename, parent_id, parent_path,
          extension, mimetype, category, isalink, filesize,
          geometry, publish_time, upload_time,
          last_download, download_count, metadata, caption,
          'active', approval, rank
        FROM trash_media
        WHERE CONCAT(parent_path, user_filename) LIKE CONCAT(_old_node_path, '/%');

        SELECT COALESCE(SUM(filesize), 0) INTO _total_filesize
        FROM trash_media
        WHERE id = _id
          OR CONCAT(parent_path, user_filename) LIKE CONCAT(_old_node_path, '/%');
      ELSE
        SELECT filesize INTO _total_filesize
        FROM trash_media WHERE id = _id;
      END IF;

      -- Update paths for restored root node
      UPDATE media
      SET parent_path = parent_path(id),
          file_path = clean_path(CONCAT(parent_path(id), '/', user_filename, '.', extension))
      WHERE id = _id;

      -- Update paths for folder children
      IF _category = 'folder' THEN
        SELECT CONCAT(parent_path(id), user_filename) INTO _new_node_path
        FROM media WHERE id = _id;

        UPDATE media
        SET parent_path = parent_path(id),
            file_path = clean_path(CONCAT(parent_path(id), '/', user_filename, '.', extension))
        WHERE CONCAT(parent_path, user_filename) LIKE CONCAT(_new_node_path, '/%');
      END IF;

      -- Update disk_usage
      IF _hub_id IS NOT NULL AND _total_filesize > 0 THEN
        UPDATE yp.disk_usage
        SET size = IFNULL(size, 0) + _total_filesize
        WHERE hub_id = _hub_id;
      END IF;

      -- Delete from trash
      IF _category = 'folder' THEN
        DELETE FROM trash_media
        WHERE id = _id
          OR CONCAT(parent_path, user_filename) LIKE CONCAT(_old_node_path, '/%');
      ELSE
        DELETE FROM trash_media WHERE id = _id;
      END IF;

      COMMIT;

      -- Return restored node
      SELECT * FROM media WHERE id = _id;
    END IF;
  END IF;
END$

DELIMITER ;