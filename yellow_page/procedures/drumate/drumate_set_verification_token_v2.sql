DELIMITER $

DROP PROCEDURE IF EXISTS `drumate_set_verification_token_v2`$
CREATE PROCEDURE `drumate_set_verification_token_v2`(
  IN _id    VARBINARY(16),
  IN _email VARCHAR(255),
  IN _token VARCHAR(255)
)
BEGIN
  -- v2 of drumate_set_verification_token. Same job -- mint one active
  -- verification token for a drumate and stage the address in
  -- unverified_email -- with ONE difference: the token is supplied by the
  -- caller instead of being generated here.
  --
  -- Why: v1 used `sha2(uuid(), 224)`. MariaDB's UUID() is version 1, i.e.
  -- timestamp + clock sequence + MAC address, and sha2() adds no entropy at
  -- all -- guess the input and you can compute the digest yourself. Measured
  -- on production, two consecutive calls returned
  --   a3bd719d-8dbd-11f1-bd71-4abbf46ce6b1
  --   a3bd7241-8dbd-11f1-bd71-4abbf46ce6b1
  -- identical in time_mid, time_hi (version nibble 1), clock_seq and node,
  -- differing only by 164 ticks of time_low. So one token discloses every
  -- field except a narrow timestamp, and the caller of resend_verification
  -- chooses when that timestamp happens.
  --
  -- The caller now passes crypto.randomBytes(32).toString('hex') -- 256 bits
  -- from a CSPRNG. This is a NEW procedure rather than a change to v1 because
  -- the signature gains a parameter: production keeps calling the 2-argument
  -- v1 until the plugin that calls this ships, so the apply is never breaking.
  --
  -- Everything else is deliberately byte-identical to v1, including the
  -- DELETE-then-INSERT that enforces one active token per drumate.
  DELETE FROM verification WHERE drumate_id = _id;
  INSERT INTO verification (drumate_id, token, ctime)
    VALUES (_id, _token, UNIX_TIMESTAMP());

  UPDATE drumate SET unverified_email = _email WHERE id = _id;

  SELECT _token AS token;
END$

DELIMITER ;
