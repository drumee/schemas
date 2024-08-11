-- =====================================
-- BEGIN OF `page` table
-- =====================================
CREATE TABLE `page` (
  `id` INT(6) NOT NULL AUTO_INCREMENT,
  `tag` varchar(400) CHARACTER SET ascii NOT NULL,
  `author` varchar(80) NOT NULL,
  `comment` text NOT NULL,
  `source` JSON NOT NULL,
  `native` JSON NOT NULL,
  `lang` varchar(10) CHARACTER SET ascii GENERATED ALWAYS AS (JSON_EXTRACT(native, '$.lang')),
  `device` enum('mobile','desktop','tablet') CHARACTER SET ascii GENERATED ALWAYS AS (JSON_EXTRACT(native, '$.device')),
  `context` enum('page','slider','slideshow') CHARACTER SET ascii GENERATED ALWAYS AS (JSON_EXTRACT(native, '$.context')),
  `backup` JSON NOT NULL,
  `status` enum('active','deleted','locked','backup','readonly') NOT NULL,
  `ctime` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `version` varchar(10) CHARACTER SET ascii NOT NULL DEFAULT '1.0.0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

