-- Trigger: Auto-sync quota_usage cache when disk_usage changes
-- Fires: After INSERT/UPDATE/DELETE on yp.disk_usage
-- Purpose: Keep quota_usage.cached_usage in sync with disk_usage

DELIMITER $

USE yp$

DROP TRIGGER IF EXISTS `disk_usage_after_insert`$
DROP TRIGGER IF EXISTS `disk_usage_after_update`$
DROP TRIGGER IF EXISTS `disk_usage_after_delete`$

-- AFTER INSERT
CREATE TRIGGER `disk_usage_after_insert`
AFTER INSERT ON `disk_usage`
FOR EACH ROW
BEGIN
  DECLARE _domain_id INT DEFAULT 0;

  SELECT dom_id FROM entity WHERE id = NEW.hub_id INTO _domain_id;

  IF _domain_id > 1 THEN
    IF EXISTS (SELECT 1 FROM quota WHERE domain_id = _domain_id) THEN
      INSERT INTO quota_usage (domain_id, cached_usage, ctime, mtime)
      VALUES (_domain_id, NEW.size, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
      ON DUPLICATE KEY UPDATE
        cached_usage = cached_usage + NEW.size,
        mtime = UNIX_TIMESTAMP();
    END IF;
  END IF;
END$

-- AFTER UPDATE
CREATE TRIGGER `disk_usage_after_update`
AFTER UPDATE ON `disk_usage`
FOR EACH ROW
BEGIN
  DECLARE _domain_id INT DEFAULT 0;
  DECLARE _delta BIGINT DEFAULT 0;

  SET _delta = NEW.size - OLD.size;

  IF _delta != 0 THEN
    SELECT dom_id FROM entity WHERE id = NEW.hub_id INTO _domain_id;

    IF _domain_id > 1 THEN
      IF EXISTS (SELECT 1 FROM quota WHERE domain_id = _domain_id) THEN
        INSERT INTO quota_usage (domain_id, cached_usage, ctime, mtime)
        VALUES (_domain_id, GREATEST(0, _delta), UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
        ON DUPLICATE KEY UPDATE
          cached_usage = GREATEST(0, cached_usage + _delta),
          mtime = UNIX_TIMESTAMP();
      END IF;
    END IF;
  END IF;
END$

-- AFTER DELETE
CREATE TRIGGER `disk_usage_after_delete`
AFTER DELETE ON `disk_usage`
FOR EACH ROW
BEGIN
  DECLARE _domain_id INT DEFAULT 0;
  
  SELECT dom_id FROM entity WHERE id = OLD.hub_id INTO _domain_id;
  
  IF _domain_id > 1 THEN
    UPDATE quota_usage 
    SET cached_usage = GREATEST(0, cached_usage - OLD.size),
        mtime = UNIX_TIMESTAMP()
    WHERE domain_id = _domain_id;
  END IF;
END$

DELIMITER ;