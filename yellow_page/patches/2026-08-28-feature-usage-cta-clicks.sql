-- File: schemas/yellow_page/patches/2026-08-28-feature-usage-cta-clicks.sql
-- Purpose: widen yp.feature_usage.feature to carry the two Extended-page
--          intent signals.
--
-- 'upgrade_click'    -- somebody opened billing/plans. Marked inside
--                       desk.openBillingPage(), so it counts every route in:
--                       sidebar, Settings card, storage upsell, admin upsell,
--                       and the #/desk/billing deep link.
-- 'selfhosted_click' -- somebody opened the Get help > Self-hosting page.
--
-- NEITHER IS BACKFILLABLE. A click that was never recorded leaves no trace in
-- any table, log or queue -- unlike 'gdrive', whose history turned out to be
-- recoverable from the surviving Bull job records. Both bars start at zero on
-- deploy day and analytics.extended reports `since` so the page can say so.
--
-- IDEMPOTENT. MODIFY COLUMN restates the whole definition, so re-applying is a
-- no-op rather than an error -- which is what lets this file sit in
-- manifest.txt safely.
--
-- LIVES UNDER yellow_page/patches/, NOT THE TOP-LEVEL patches/ DIRECTORY.
-- bin/patch-from-manifest routes a manifest line by its <db-class>/ prefix and
-- has no branch for a bare `patches/` one, so such a line resolves to
-- target=null and is SKIPPED in silence; bin/patch-from-file rejects it
-- outright (patch.js `_types`).
--
-- APPLY THIS BEFORE PATCHING feature_mark, and both before deploying
-- server-team. feature_mark SIGNALs on an unknown feature, and a non-fatal
-- SIGNAL does not reject -- the driver rolls back and ENDS THE SHARED yp
-- CONNECTION, which surfaces as stalled sibling requests, not a warning.

ALTER TABLE `feature_usage`
  MODIFY COLUMN `feature`
    enum('upload','chat','task','meeting','file_thread','gdrive','upgrade_click','selfhosted_click') NOT NULL
    COMMENT 'Which tracked feature or intent signal this row records';
