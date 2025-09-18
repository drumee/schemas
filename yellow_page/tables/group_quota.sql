CREATE TABLE IF NOT EXISTS `group_quota` (
  `category` VARCHAR(512) DEFAULT "regular",
  `private_hub` VARCHAR(16) DEFAULT "Infinity",
  `share_hub` VARCHAR(16) DEFAULT "Infinity",
  `public_hub` VARCHAR(16) DEFAULT "Infinity",
  `desk_disk` VARCHAR(32) DEFAULT "Infinity",
  `hub_disk` VARCHAR(32) DEFAULT "Infinity",
  `organization` VARCHAR(32) DEFAULT "0",
  `conference` VARCHAR(32) DEFAULT "Infinity",
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_general_ci;

LOCK TABLES `group_quota` WRITE;
INSERT IGNORE INTO `group_quota` VALUES 
  ('guest','10','10','0','2147483648','1073741824','0','0'),
  ('default','Infinity','Infinity','Infinity','Infinity','Infinity','0','Infinity'),
  ('regular','Infinity','Infinity','Infinity','Infinity','Infinity','Infinity','Infinity'),
  ('sandbox','10','10','2','209715200','209715200','0','10'),
  ('system','0','0','0','0','0','0','0');
UNLOCK TABLES;
