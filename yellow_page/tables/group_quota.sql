CREATE TABLE `group_quota` (
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
