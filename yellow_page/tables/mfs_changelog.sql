DROP TABLE IF EXISTS `mfs_changelog`;
CREATE TABLE `mfs_changelog` (
  `id` INT(11) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` int(11) unsigned NOT NULL,
  `uid` VARCHAR(16) CHARACTER SET ascii,
  `hub_id` VARCHAR(16) CHARACTER SET ascii,
  `event` VARCHAR(100) CHARACTER SET ascii,
  `ref_hubid` VARCHAR(16) CHARACTER SET ascii GENERATED ALWAYS AS 
    (IF(event = "media.copy", JSON_VALUE(`dest`,'$.hub_id'), JSON_VALUE(`src`,'$.hub_id'))) VIRTUAL,
  `ref_pid` VARCHAR(16) CHARACTER SET ascii GENERATED ALWAYS AS 
    (IF(event = "media.copy", JSON_VALUE(`dest`,'$.pid'), JSON_VALUE(`src`,'$.pid'))) VIRTUAL,
  `ref_nid` VARCHAR(16) CHARACTER SET ascii GENERATED ALWAYS AS 
    (IF(event = "media.copy", JSON_VALUE(`dest`,'$.nid'), JSON_VALUE(`src`,'$.nid'))) VIRTUAL,
  `ref_ctime` VARCHAR(16) CHARACTER SET ascii GENERATED ALWAYS AS 
    (IF(event = "media.copy", JSON_VALUE(`dest`,'$.ctime'), JSON_VALUE(`src`,'$.ctime'))) VIRTUAL,
  src JSON,
  dest JSON DEFAULT '{}',
  PRIMARY KEY (`id`)
);
