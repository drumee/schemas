DROP TABLE IF EXISTS tmp_media;
CREATE TABLE tmp_media (
  `id` varchar(16) DEFAULT NULL,
  `origin_id` varchar(16) DEFAULT NULL,
  `file_path` varchar(512) DEFAULT NULL,
  `user_filename` varchar(128) DEFAULT NULL,
  `parent_id` varchar(16)  NULL DEFAULT '',
  `parent_path` varchar(1024) ,
  `extension` varchar(100)  DEFAULT '',
  `mimetype` varchar(100) ,
  `category`  varchar(16) ,
  `isalink` tinyint(2) unsigned  DEFAULT '0',
  `filesize` int(20) unsigned  DEFAULT '0',
  `geometry` varchar(200)  DEFAULT '0x0',
  `publish_time` int(11) unsigned  DEFAULT '0',
  `upload_time` int(11) unsigned  DEFAULT '0',
  `status` varchar(20)  DEFAULT 'active',
  `rank` tinyint(4)  DEFAULT '0'
);

DROP TABLE IF EXISTS tmp_id;
CREATE TABLE tmp_id (
  `nid` varchar(16) NOT NULL,
  mfs_root varchar(1024) NOT NULL
);
