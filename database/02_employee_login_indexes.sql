-- InterPOS employee login indexes
-- Run once after database/01_schema.sql on an existing database.

CREATE UNIQUE INDEX UX_EMPLOYEE_STORE_LOGIN
  ON EMPLOYEE (STORE_ID, LOGIN_ID);

CREATE INDEX IX_EMPLOYEE_STORE_ACTIVE
  ON EMPLOYEE (STORE_ID, ACTIVE_YN);
