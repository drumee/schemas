-- common tables
create table if not exists `language` like template_common.language;
create table if not exists `acl` like template_common.acl;
create table if not exists `block` like template_common.block;
create table if not exists `block_history` like template_common.block_history;
create table if not exists `chat` like template_common.chat;
create table if not exists `content_tag` like template_common.content_tag;
create table if not exists `font` like template_common.font;
create table if not exists `font_face` like template_common.font_face;
create table if not exists `font_link` like template_common.font_link;
create table if not exists `huber` like template_common.huber;  -- SHALL BE DEPRECATED
create table if not exists `layout` like template_common.layout; -- SHALL BE DEPRECATED
create table if not exists `media` like template_common.media;
create table if not exists `media_stats` like template_common.media_stats;
create table if not exists `message` like template_common.message;
create table if not exists `notification` like template_common.notification;
create table if not exists `permission` like template_common.permission;
create table if not exists `seo` like template_common.seo;
create table if not exists `style` like template_common.style;
create table if not exists `action_log` like template_common.action_log;
create table if not exists `task` like template_common.task;
create table if not exists `task_file` like template_common.task_file;
