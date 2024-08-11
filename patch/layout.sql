-- CREATE TABLE IF NOT EXISTS `hashtag` (
--   `label` varchar(100) CHARACTER SET utf8mb4 NOT NULL,
--   `hash_id` varbinary(16) NOT NULL,
--   `ctime` int(11) NOT NULL,
--   `mtime` int(11) NOT NULL,
--   KEY `label` (`label`,`hash_id`),
--   KEY `ctime` (`ctime`,`mtime`)
-- ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
--
-- ALTER TABLE  `layout` CHANGE  `hash`  `hash_tag` VARCHAR( 127 ) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL;
--
-- update layout set label=url, hash_tag=url;

-- ALTER TABLE  `layout` ADD  `status` ENUM(  'active',  'deleted' ) NOT NULL AFTER  `description`;

-- ALTER TABLE  `layout` ADD  `version` VARCHAR( 10 ) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL DEFAULT  '1.0.0',
-- ADD INDEX (  `version` );

-- ALTER TABLE  `layout` ADD  `owner_id` VARBINARY( 16 ) NOT NULL AFTER  `id` , ADD INDEX (  `owner_id` );
-- ALTER TABLE  `layout` CHANGE  `owner_id`  `owner_id` VARCHAR( 255 ) NOT NULL;
-- update layout set owner_id=get_ident();

-- ALTER TABLE `layout` DROP `owner_id`;
-- ALTER TABLE  `layout` ADD  `letc` MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL AFTER  `description` , ADD FULLTEXT (`letc`);
-- update layout set letc=description;
-- update layout set letc=replace(letc, 'widget:text', 'widget:document');
-- update layout set letc=replace(letc, '"type"', '"cvType"');
-- ALTER TABLE `layout` DROP `description`;

-- ALTER TABLE  `layout` ADD  `desktop` MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL AFTER  `letc` , ADD  `tablet` MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL AFTER  `desktop` , ADD  `mobile` MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL AFTER  `tablet` , ADD FULLTEXT (`desktop` ,`tablet` , `mobile`);
-- update layout set desktop=letc;
-- ALTER TABLE  `layout` ADD  `hashtag` VARCHAR( 127 ) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL AFTER  `hash_tag` , ADD INDEX (  `hashtag` );
-- update layout set hashtag=hash_tag;
-- ALTER TABLE `layout` DROP `url_key`,  DROP `url`,  DROP `hash_tag`,  DROP `letc`,  DROP `screen`;
-- ALTER TABLE  `layout` ADD  `ltype` ENUM(  'layout',  'slide' ) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL DEFAULT  'layout' AFTER  `id` , ADD INDEX (  `ltype` );

-- ALTER TABLE  `layout` CHANGE  `ltype`  `context` ENUM(  'page',  'slider' ) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL DEFAULT  'page';

-- ALTER TABLE  `layout` CHANGE  `context`  `context` ENUM(  'page',  'slider',  'slideshow' ) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL DEFAULT  'page';

-- ALTER TABLE `layout` CHANGE `status` `status` ENUM('active','deleted','locked', 'drafting') CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
-- ALTER TABLE `layout` ADD `draft` MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL AFTER `desktop`;
-- ALTER TABLE `layout` DROP INDEX `desktop`, ADD FULLTEXT `content` (`desktop`, `tablet`, `mobile`, `draft`);
-- ALTER TABLE `layout` DROP INDEX `comment`, ADD FULLTEXT `comment` (`comment`);

-- ALTER TABLE `layout` CHANGE `status` `status` ENUM('active','deleted','locked','backup','readonly') CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
-- ALTER TABLE `layout` CHANGE `draft` `backup` MEDIUMTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;

-- ALTER TABLE layout DROP INDEX hashtag;
-- ALTER TABLE `layout` DROP INDEX `hashtag_2`, ADD UNIQUE `hashtag` (`hashtag`) USING BTREE;


-- ALTER TABLE `layout`
-- ADD `tag` VARCHAR(400) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `hashtag`,
-- ADD `hash` VARCHAR(500) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `tag`,
-- ADD `device` ENUM('mobile', 'desktop', 'tablet') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'desktop' AFTER `hash`,
-- ADD `lang` VARCHAR(10) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'fr' AFTER `device`,
-- ADD `content` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL AFTER `desktop`,
-- ADD FULLTEXT (`content`);
-- update layout set content=desktop, tag=hashtag, hash=concat(hashtag, '!', lang, '!', device);

-- ALTER TABLE layout DROP INDEX label;
-- ALTER TABLE layout DROP INDEX content;
-- ALTER TABLE layout DROP INDEX content_2;
-- ALTER TABLE layout DROP INDEX comment;
-- ALTER TABLE `layout` CHANGE `comment` `comment` TEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
-- ALTER TABLE layout ADD FULLTEXT `content` (`content`, `comment`);
-- ALTER TABLE layout ADD UNIQUE `hash` (`hash`);
-- ALTER TABLE layout ADD INDEX `tag` (`tag`);

-- ALTER TABLE `layout` DROP INDEX hash;
-- ALTER TABLE `layout` ADD UNIQUE KEY `hash` (`hash`)USING BTREE;
-- ALTER TABLE `layout` CHANGE `backup` `backup` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
-- ALTER TABLE `layout` CHANGE `desktop` `desktop_tmp` MEDIUMTEXT;
-- ALTER TABLE `layout` DROP `desktop_tmp`;



-- ALTER TABLE `layout` DROP `hashtag_o`;

-- ALTER TABLE `layout` ADD `footnote` TEXT CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL AFTER `content`, ADD FULLTEXT (`footnote`);

-- ALTER TABLE `layout` CHANGE `context` `context` ENUM('page','slider','slideshow', 'menu') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'page';

-- ALTER TABLE `layout` CHANGE `status` `status` ENUM('active','deleted','locked','backup','readonly', 'maiden') CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;

-- ALTER TABLE `layout` CHANGE `status` `status` ENUM('active','deleted','locked','backup','readonly','draft') CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;
-- ALTER TABLE `layout` DROP INDEX IF EXISTS  `content`;
-- ALTER TABLE `layout` DROP INDEX  IF EXISTS `footnote`;
-- ALTER TABLE `layout` CHANGE `comment` `comment` TEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
-- ALTER TABLE `layout` CHANGE `content` `content` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL;
-- ALTER TABLE `layout` DROP IF EXISTS `newbie`;
-- ALTER TABLE `layout` DROP IF EXISTS `expert`;
-- ALTER TABLE `layout` ADD `newbie` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL AFTER `backup`, ADD `expert` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL AFTER `newbie`;
-- ALTER TABLE `layout` ADD FULLTEXT `content` (`content`, `comment`, `newbie`, `expert`);

-- ALTER TABLE `layout` CHANGE `comment` `comment` TEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;
-- ALTER TABLE `layout` CHANGE `footnote` `footnote` TEXT CHARACTER SET ascii COLLATE ascii_general_ci NULL DEFAULT NULL;
-- ALTER TABLE `layout` CHANGE `newbie` `newbie` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;
-- ALTER TABLE `layout` CHANGE `expert` `expert` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;
-- ALTER TABLE `layout` CHANGE `content` `content` MEDIUMTEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;
-- ALTER TABLE `layout` CHANGE `hash` `hash` VARCHAR(500) CHARACTER SET ascii COLLATE ascii_general_ci NULL DEFAULT NULL;

-- ALTER TABLE `layout` DROP INDEX `content`, ADD FULLTEXT `content` (`content`);

-- ALTER TABLE `layout` ADD `editor` ENUM('designer', 'creator') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'creator' AFTER `context`, ADD INDEX (`editor`);

update layout set editor='designer';