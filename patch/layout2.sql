-- ALTER TABLE layout DROP PRIMARY KEY;
-- ALTER TABLE layout DROP `sys_id`;
-- ALTER TABLE layout ADD UNIQUE(`id`);
-- ALTER TABLE layout ADD `sys_id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;
-- ALTER TABLE `layout` ADD `hashtag` VARCHAR(500) NOT NULL AFTER `id`, ADD `type` ENUM('page','block','menu','header','footer') NOT NULL DEFAULT 'block' AFTER `hashtag`;
-- update layout set hashtag=tag;
-- ALTER TABLE layout ADD UNIQUE(`hashtag`);

-- ALTER TABLE `layout` CHANGE `lang` `lang` VARCHAR(2000) DEFAULT NULL;

-- ALTER TABLE `layout` CHANGE `device` `device` VARCHAR(2000) DEFAULT NULL;

-- update layout set device='{"desktop":"desktop"}';
-- update layout set lang='{"fr":"fr"}';

-- ALTER TABLE `layout` ADD `author_id` VARBINARY(16) NOT NULL AFTER `id`, ADD INDEX (`author_id`);

-- update layout set author_id=if((select id from yp.entity where entity.ident=author) is null, '', (select id from yp.entity where entity.ident=author));
-- update layout set author_id= if(author_id='', 'df0db400a22011e0', author_id);
-- update layout set device="desktop";

-- ALTER TABLE `layout` CHANGE `context` `context` ENUM('page','slider','slideshow','menu','creator','designer') CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'creator';
-- ALTER TABLE `layout` CHANGE `status` `status` ENUM('active','deleted','locked','backup','readonly','draft','exported') CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;

ALTER TABLE `layout` CHANGE `type` `type` ENUM('page','block','menu','header','footer','slider','gallery') CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT 'block';