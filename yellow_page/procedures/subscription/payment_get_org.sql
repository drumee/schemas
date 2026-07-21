DELIMITER $
DROP PROCEDURE IF EXISTS `payment_get_org`$
CREATE PROCEDURE `payment_get_org`(
  IN _uid VARCHAR(16) CHARACTER SET ascii
)
BEGIN
  -- The org this user is the billing owner of (organisation.owner_id), plus the
  -- org's existing Stripe customer (subscription_new keyed on the organisation id).
  -- link/ident: the org's vhost — emails must deep-link the RECIPIENT's host
  -- (the session cookie is host-scoped; a main-domain link lands signed-out).
  SELECT o.id, o.domain_id, o.name, o.owner_id, o.link, o.ident, s.customer_id
  FROM yp.organisation o
  LEFT JOIN yp.subscription_new s ON s.entity_id = o.id
  WHERE o.owner_id = _uid
  LIMIT 1;
END $
DELIMITER ;
