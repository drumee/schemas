-- yp.organisation.name must NOT be globally unique.
--
-- Every path that creates an organisation names it from the payer's display
-- name -- promo._provisionOrg builds `${fullname}'s Team`, and the checkout
-- form pre-fills the same shape -- so two accounts whose display names match
-- collide on UNIQUE KEY `name`. org_provision then dies with ER_DUP_ENTRY
-- (errno 1062) and the whole flow fails:
--
--   * LAUNCH30 claim  -> "Something went wrong. Please reload and try again."
--     Observed live on drumee.in for two accounts (2026-07-31, 2026-08-09):
--     'Thao Linh Hoang''s Team' and 'To Bảo Phạm''s Team' each already
--     existed under a DIFFERENT owner, and each user retried three times.
--   * payment.checkout -> worse: the org is provisioned by the Stripe
--     webhook AFTER the card is charged, so the throw leaves a paying
--     customer with no organisation while Stripe retries the event.
--
-- The ident, not the name, is the identity. org_provision already guards it
-- against both entity.ident and organisation.ident, and _provisionOrg retries
-- with a random suffix until it is free; domain_id / id / link / owner_id keep
-- their UNIQUE keys. Nothing anywhere reads an organisation BY name: the only
-- name-shaped lookups in yp resolve a DOMAIN name (org_provision itself,
-- hubname_exists, unique_hostname), and no service in server-team, admin-api,
-- analytics-server or loby selects on organisation.name.
--
-- A display label shared across tenants is also correct product behaviour --
-- two unrelated companies may both call themselves Acme, and neither should
-- be able to squat the name platform-wide.
--
-- Dropping it in favour of a uniquifier ('... (2)') was rejected: it hands
-- people a name they did not choose to satisfy a constraint nothing needs.
--
-- IDEMPOTENT: the index is dropped only if present, so replaying this patch
-- (or running it on a database provisioned after tables/organisation.sql was
-- updated to match) is a no-op. Data is untouched -- dropping an index writes
-- no rows.

SET @drop_name_idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
   WHERE TABLE_SCHEMA = 'yp'
     AND TABLE_NAME   = 'organisation'
     AND INDEX_NAME   = 'name'
);

SET @sql := IF(@drop_name_idx > 0,
  'ALTER TABLE `yp`.`organisation` DROP INDEX `name`',
  'DO 0');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
