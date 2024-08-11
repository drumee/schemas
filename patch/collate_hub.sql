ALTER TABLE article CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE comment CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE drums CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE log CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE members CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE message CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE poll CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;


-- ALTER DATABASE B_somanos CHARACTER SET utf8 COLLATE utf8_general_ci;

Applying patches/collate_common.sql to 9_1d146e761d146e
ERROR 1071 (42000) at line 4: Specified key was too long; max key length is 1000 bytes
------------ ------------------
Applying patches/collate_common.sql to b_32353271323532
ERROR 1071 (42000) at line 4: Specified key was too long; max key length is 1000 bytes
-