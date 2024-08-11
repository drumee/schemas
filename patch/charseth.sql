-- ALTER TABLE attachments  CHANGE `filename` `filename` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci; 
-- ALTER TABLE attachments  CHANGE `filetype` `filetype` varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci; 
-- 
-- ALTER TABLE comment CHANGE `id` `id`     varbinary(16);      
-- ALTER TABLE comment CHANGE `ref_id` `ref_id`       varbinary(16);
-- ALTER TABLE comment CHANGE `owner_id` `owner_id`     varbinary(16);
-- ALTER TABLE comment CHANGE `author_id` `author_id`    varbinary(16);
-- ALTER TABLE comment CHANGE `lang` `lang`  varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci;   
-- ALTER TABLE comment CHANGE `status` `status`  enum('draft','validated','online')  CHARACTER SET ascii COLLATE ascii_general_ci; 

ALTER TABLE layout DROP INDEX content;   
ALTER TABLE layout DROP INDEX footnote;   
ALTER TABLE layout CHANGE `author` `author` varchar(80) CHARACTER SET ascii COLLATE ascii_general_ci;          
ALTER TABLE layout CHANGE `comment` `comment` varchar(512) CHARACTER SET utf8 COLLATE utf8_unicode_ci;        
ALTER TABLE layout CHANGE `content` `content` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci;       
ALTER TABLE layout CHANGE `backup` `backup` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci;              
ALTER TABLE layout CHANGE `status` `status` enum('active','deleted','locked','backup','readonly','draft') CHARACTER SET ascii COLLATE ascii_general_ci;
ALTER TABLE layout ADD FULLTEXT `content` (`comment`, `content`, `backup`);

ALTER TABLE log  CHANGE `user_id` `user_id`    varbinary(16);
ALTER TABLE log  CHANGE `drum_id` `drum_id`    varbinary(16);
ALTER TABLE log  CHANGE `thread_id` `thread_id`  varbinary(16);
ALTER TABLE log  CHANGE `state` `state`  varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci;   

ALTER TABLE media DROP INDEX content;   
ALTER TABLE media  CHANGE `file_path` `file_path` varchar(512) CHARACTER SET utf8 COLLATE utf8_unicode_ci;       
ALTER TABLE media  CHANGE `user_filename` `user_filename` varchar(80) CHARACTER SET utf8 COLLATE utf8_unicode_ci;  
ALTER TABLE media  CHANGE `metadata` `metadata` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci;         
ALTER TABLE media  CHANGE `caption` `caption` mediumtext CHARACTER SET utf8 COLLATE utf8_unicode_ci;          
ALTER TABLE media ADD FULLTEXT `content` (`caption`, `user_filename`, `file_path`, `metadata`);

ALTER TABLE message  CHANGE `firstname` `firstname` varchar(60) CHARACTER SET utf8 COLLATE utf8_unicode_ci;  
ALTER TABLE message  CHANGE `lastname` `lastname` varchar(60) CHARACTER SET utf8 COLLATE utf8_unicode_ci;   
ALTER TABLE message  CHANGE `content` `content` text   CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE message  CHANGE `referer` `referer` varchar(512) CHARACTER SET ascii COLLATE ascii_general_ci;  
ALTER TABLE message  CHANGE `ip` `ip` varchar(80) CHARACTER SET ascii COLLATE ascii_general_ci;       
ALTER TABLE poll     CHANGE `name` `name`  varchar(60) CHARACTER SET utf8 COLLATE utf8_unicode_ci;      
ALTER TABLE tag      CHANGE `hash_id` `hash_id`  varbinary(16);
