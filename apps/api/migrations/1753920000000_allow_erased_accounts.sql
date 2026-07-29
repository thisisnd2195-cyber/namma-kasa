-- Up Migration

-- users_credential_present asserts that every account can sign in. That is
-- right for a live account and wrong for an erased one: DPDP erasure removes
-- the credential along with the rest of the personal data, and the row remains
-- only so the ward's collection history stays whole.
--
-- The constraint now describes live accounts and steps aside for erased ones,
-- which are identifiable by their tombstoned phone value.

ALTER TABLE users DROP CONSTRAINT users_credential_present;

ALTER TABLE users ADD CONSTRAINT users_credential_present CHECK (
  phone LIKE 'deleted-%'
  OR (auth_provider = 'password' AND password_hash IS NOT NULL)
  OR (auth_provider = 'google'   AND email IS NOT NULL)
);

-- Down Migration

ALTER TABLE users DROP CONSTRAINT users_credential_present;

ALTER TABLE users ADD CONSTRAINT users_credential_present CHECK (
  (auth_provider = 'password' AND password_hash IS NOT NULL) OR
  (auth_provider = 'google'   AND email IS NOT NULL)
);
