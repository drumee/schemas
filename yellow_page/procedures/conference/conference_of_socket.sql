DELIMITER $

DROP PROCEDURE IF EXISTS `conference_of_socket`$
-- Every conference a socket is currently sitting in.
--
-- Needed on the abrupt-disconnect path: a client that drops (mobile losing its
-- radio, backgrounding, a network switch) never gets to call conference.leave,
-- so the push router has to run the leave itself — but conference_leave is
-- keyed by room, and all the router knows is the socket. `uid` comes along so
-- the peers can be told WHO left without a second lookup.
CREATE PROCEDURE `conference_of_socket`(
  IN _socket_id VARCHAR(64)
)
BEGIN
  SELECT room_id, hub_id, uid, `role`, `type`
    FROM conference
    WHERE socket_id = _socket_id;
END$

DELIMITER ;

-- #####################
