ALTER TABLE `media` CHANGE `id` `id` VARBINARY(16) NOT NULL;
ALTER TABLE `media` CHANGE `owner_id` `owner_id` VARBINARY(16) NOT NULL;
ALTER TABLE `media` CHANGE `origin_id` `origin_id` VARBINARY(16) NOT NULL;
ALTER TABLE `media` CHANGE `area_id` `area_id` VARBINARY(16) NOT NULL;

ALTER TABLE `layout` CHANGE `id` `id` VARBINARY(16) NOT NULL;

-- ALTER TABLE `poll` CHANGE `id` `id` VARBINARY(16) NOT NULL;
-- ALTER TABLE `poll` CHANGE `author_id` `author_id` VARBINARY(16) NOT NULL;
