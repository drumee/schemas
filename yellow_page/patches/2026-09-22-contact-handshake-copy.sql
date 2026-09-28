-- Straighten the two canned contact-handshake greetings.
--
-- contact.invite_accept seeds a brand-new contact conversation with a pair of
-- greetings read from yp.languages through Cache.message:
--   _contact_invite_chat_msg  the inviter's "welcome"
--   _contact_accept_chat_msg  the accepter's "I have accepted"
--
-- Both English rows carry stray whitespace from a template that once
-- interpolated a name — "Hi ," with the comma orphaned, and "Network !" with
-- the French space before the bang. Nothing ever filled the name in, so the
-- messages render with the gap visible. km/ru/zh hold the same English string
-- (they were never translated); fr is already clean and is left alone.
--
-- Idempotent: each WHERE matches only the unfixed text, so a re-run is a no-op.
-- Mirrors templates/factory/seed/yp.sql so a fresh factory install and an
-- upgraded one agree. Runtime reads the JSON lexicon
-- (server-essentials/lib/dataset/locale/*.json), fixed alongside this; the
-- table is the source those files are generated from.
UPDATE `languages`
   SET `des` = 'Hi,\nWelcome to my Drumee Network!'
 WHERE `key_code` = '_contact_invite_chat_msg'
   AND `des` = 'Hi, \nWelcome to my Drumee Network !';

UPDATE `languages`
   SET `des` = 'Hi,\nI have accepted your invitation.'
 WHERE `key_code` = '_contact_accept_chat_msg'
   AND `des` = 'Hi ,\nI have accepted your invitation.';
