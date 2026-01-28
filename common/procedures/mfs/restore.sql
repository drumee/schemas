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

  -- Get home_id and hub_id first
  SELECT id FROM media WHERE (parent_id IS NULL OR parent_id="" OR parent_id='0') INTO _home_id;
  SELECT id FROM yp.entity WHERE db_name=database() INTO _hub_id;

  -- Check if trying to restore root
  IF _id IS NULL OR _id = _home_id THEN 
    SELECT 1 AS failed, "Could not restore root itself" AS message;
  ELSE
    -- Read from TRASH_MEDIA
    SELECT category, parent_id 
    INTO _category, _parent_id
    FROM trash_media 
    WHERE id = _id;

    START TRANSACTION;

    -- For folder operations, get the old base path first (from trash_media)
    IF _category = 'folder' THEN
      SELECT CONCAT(parent_path, user_filename) INTO _old_node_path
      FROM trash_media WHERE id = _id;
    END IF;

    -- Insert back into media from trash_media
    IF _category = 'folder' THEN
      -- For folders, restore recursively
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
      WHERE id = _id 
        OR CONCAT(parent_path, user_filename) LIKE CONCAT(_old_node_path, '/%');

      -- Calculate total size for folders
      SELECT COALESCE(SUM(filesize), 0)
      FROM trash_media
      WHERE id = _id
        OR CONCAT(parent_path, user_filename) LIKE CONCAT(_old_node_path, '/%')
      INTO _total_filesize;

    ELSE
      -- For files, restore single record
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
      WHERE id = _id;

      -- Get filesize
      SELECT filesize FROM trash_media WHERE id = _id INTO _total_filesize;
    END IF;

    -- Update parent_path and file_path for restored items
    UPDATE media 
    SET parent_path = parent_path(id),
        file_path = clean_path(CONCAT(parent_path(id), '/', user_filename, '.', extension))
    WHERE id = _id;

    IF _category = 'folder' THEN
      -- Get the new path after restoration
      SELECT CONCAT(parent_path(id), user_filename) FROM media WHERE id = _id INTO _new_node_path;
      UPDATE media 
      SET parent_path = parent_path(id),
          file_path = clean_path(CONCAT(parent_path(id), '/', user_filename, '.', extension))
      WHERE CONCAT(parent_path(id), user_filename) LIKE CONCAT(_new_node_path, '/%');
    END IF;

    -- Update disk_usage
    IF _hub_id IS NOT NULL AND _total_filesize > 0 THEN
      UPDATE yp.disk_usage 
      SET size = IFNULL(size, 0) + _total_filesize 
      WHERE hub_id = _hub_id;
    END IF;

    -- Delete from trash_media using old path
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
END$

DELIMITER ;