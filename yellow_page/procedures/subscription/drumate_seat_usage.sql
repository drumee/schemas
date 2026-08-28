DELIMITER $

-- =========================================================
-- drumate_seat_usage
-- Seat occupancy of a PERSONAL account (Free / Pro: "up to 3
-- members"): distinct people who are members of any hub the
-- account owns (its own desk included), plus the live pending
-- invitations to those hubs — the same "members + invites"
-- reading member_list_stats gives an organisation, so the
-- upgrade-nudge seat thresholds mean the same thing on both
-- sides. The owner is not a seat.
-- =========================================================
DROP PROCEDURE IF EXISTS `drumate_seat_usage`$
CREATE PROCEDURE `drumate_seat_usage`(
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  SELECT
    (SELECT COUNT(DISTINCT m.drumate_id)
       FROM membership m
      WHERE m.drumate_id <> _uid
        AND (m.hub_id = _uid
             OR m.hub_id IN (SELECT h.id FROM hub h WHERE h.owner_id = _uid))
    ) AS total_members,
    (SELECT COUNT(DISTINCT LOWER(TRIM(pi.email)))
       FROM pending_invitation pi
      WHERE (pi.hub_id = _uid
             OR pi.hub_id IN (SELECT h.id FROM hub h WHERE h.owner_id = _uid))
        AND (pi.expiry_time = 0 OR pi.expiry_time > UNIX_TIMESTAMP())
    ) AS pending_invites;
END$

DELIMITER ;
