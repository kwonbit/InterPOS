-- InterPOS OKPOS-style table customer details
-- Firebird 5.0 / UTF8
-- Run once after database/16_allow_negative_ingredient_stock.sql.
-- Do not execute this migration more than once.
--
-- CUSTOMER_COUNT defaults to one for existing orders so historical/open orders
-- remain readable without changing their amounts or order items.
-- ORDERER_NAME is optional.

ALTER TABLE POS_ORDER
  ADD CUSTOMER_COUNT INTEGER DEFAULT 1 NOT NULL;

ALTER TABLE POS_ORDER
  ADD ORDERER_NAME VARCHAR(60);

ALTER TABLE POS_ORDER
  ADD CONSTRAINT CK_POS_ORDER_CUSTOMER_COUNT CHECK (CUSTOMER_COUNT >= 1);
