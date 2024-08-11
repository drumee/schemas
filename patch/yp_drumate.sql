ALTER TABLE  `drumate` ADD  `registration_verified` INT(4) NOT NULL DEFAULT 0;
ALTER TABLE  `drumate` ADD  `unverified_email` VARCHAR(255) NULL;
ALTER TABLE  `drumate` MODIFY  `country` VARCHAR(150) NULL;