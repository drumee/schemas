DELIMITER $
DROP PROCEDURE IF EXISTS `font_add`$
CREATE PROCEDURE `font_add`(
  IN _name VARCHAR(128),
  IN _variant VARCHAR(128),
  IN _url VARCHAR(1024)
)
BEGIN
  INSERT INTO font(`family`, `name`, `variant`, `url`, `ctime`, `mtime`)
            values(concat(`name`, ", ", `variant`), _name, _variant, _url, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
  ON DUPLICATE KEY UPDATE `family`=concat(`name`, ", ", `variant`),
            `name`=_name, `variant`=_variant, `url`=_url, mtime=UNIX_TIMESTAMP();
  SELECT * FROM font WHERE `name`=_name;
END $

DELIMITER ;
