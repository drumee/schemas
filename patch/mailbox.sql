CREATE TABLE `mailbox2` (
  `sys_id` BIGINT(11) UNSIGNED NULL,
  `id` varchar(16) CHARACTER SET ascii NOT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `maildir` varchar(255) NOT NULL,
  `quota` bigint(20) NOT NULL DEFAULT '0',
  `local_part` varchar(255) NOT NULL,
  `domain` varchar(255) NOT NULL,
  `created` INT(11) DEFAULT NULL,
  `modified` INT(11) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`username`),
  KEY `domain` (`domain`),
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


CREATE TABLE `alias2` (
  `sys_id` BIGINT(11) UNSIGNED NULL,
  `id` varchar(16) CHARACTER SET ascii NOT NULL,
  `address` varchar(255) NOT NULL,
  `goto` text NOT NULL,
  `domain` varchar(255) NOT NULL,
  `created` INT(11) DEFAULT NULL,
  `modified` INT(11) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`address`),
  KEY `domain` (`domain`),
  KEY `id` (`id`)
)  ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;




DROP PROCEDURE IF EXISTS `create_mailbox`$
CREATE PROCEDURE `create_mailbox`(
  IN _id VARCHAR(16),
  IN _ident VARCHAR(80),
  IN _dmail VARCHAR(255),
  IN _name VARCHAR(255),
  IN _maildir VARCHAR(255),
  IN _domain VARCHAR(255),
  OUT _username VARCHAR(255)
)
BEGIN
  DECLARE _db_host VARCHAR(255);
  DECLARE _fs_host VARCHAR(255);
  DECLARE _home_dir VARCHAR(255);
  DECLARE _uid VARCHAR(16);
  DECLARE _now INT(11);
  DECLARE _fingerprint VARCHAR(100);
  DECLARE _username VARCHAR(100);

  SELECT unix_timestamp(), sha2(_id, 256) INTO _now, _fingerprint;

  INSERT INTO mailbox (`sys_id`, `id`, `username`, `password`, `name`, `maildir`, `quota`, `local_part`,
         `domain`, `created`, `modified`, `active`)
  VALUES (uuid_short(), _id, _dmail, _fingerprint, _name, _maildir, 0, _ident,
         _domain , _now, _now, 1);

  INSERT INTO alias (`id`, `address`, `goto`, `domain`, `created`, `modified`, `active`)
  VALUES (_id, _dmail, _dmail, _domain, _now, _now, 1);

  SELECT username FROM mailbox WHERE id=_id INTO _username;

END$
