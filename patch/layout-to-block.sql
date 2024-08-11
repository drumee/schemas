-- ALTER TABLE `block` DROP `context`;
-- ALTER TABLE `block` DROP `tag`;
-- ALTER TABLE `block` DROP `hash`;
-- ALTER TABLE `block` DROP `author`;
-- ALTER TABLE `block` DROP `content`;
-- ALTER TABLE `block` DROP `footnote`;
-- ALTER TABLE `block` DROP `backup`;
-- ALTER TABLE `block` DROP `newbie`;
-- ALTER TABLE `block` DROP `expert`;
-- ALTER TABLE `block` CHANGE `device` `device` ENUM('desktop','tablet','mobile') CHARACTER SET ascii COLLATE ascii_general_ci NULL DEFAULT 'desktop';
-- ALTER TABLE `block` CHANGE `lang` `lang` VARCHAR(10) CHARACTER SET ascii COLLATE ascii_general_ci NULL DEFAULT 'en';

-- ALTER TABLE `block` CHANGE `status` `status` ENUM('active','deleted','locked','backup','readonly','draft','latest') CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT 'latest';

-- ALTER TABLE `block` ADD `master_id` VARBINARY(16) NOT NULL AFTER `id`;
-- update block set master_id=id;

-- ALTER TABLE `block` CHANGE `status` `status` ENUM('online','offline','locked') CHARACTER SET ascii COLLATE ascii_general_ci NULL DEFAULT 'online';

-- ALTER TABLE `block` ADD `status2` ENUM('online', 'offline', 'locked', 'readonly') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'online' AFTER `status`;

-- ALTER TABLE `block` DROP `status`;

-- ALTER TABLE `block` CHANGE `status2` `status` ENUM('online','offline','locked','readonly') CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL DEFAULT 'online';

-- ALTER TABLE `block` DROP `master_id`;

-- ALTER TABLE block DROP INDEX id_3;
-- ALTER TABLE block DROP INDEX id_4;


delete from block;
insert into block select null, id, 1, 1, author_id, hashtag, 'page', 'designer', 'offline', ctime, mtime, version from layout;