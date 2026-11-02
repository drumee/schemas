-- File: schemas/yellow_page/tables/mkt_offer_pending.sql
-- Purpose: An offer code picked up from a signup link (?offer=TEAM1) and held
--          for the account until it pays. The checkout reads it back to apply
--          the code without the shopper typing it. One row per payer; a newer
--          link replaces the older code. Not a redemption: nothing is reserved
--          until checkout, and a row whose code has since been redeemed,
--          disabled or expired simply reads back as nothing.
CREATE TABLE IF NOT EXISTS `mkt_offer_pending` (
  `uid`    varchar(16) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `code`   varchar(64) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,
  `ctime`  int(11) unsigned NOT NULL,
  `mtime`  int(11) unsigned NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Offer code captured from a signup link, held until checkout';
