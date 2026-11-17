-- Allow ingredient stock to become negative when POS sales consume
-- more than the recorded on-hand quantity.
-- Firebird 5.0 / UTF8
-- Run once after database/15_ingredient_purchasing.sql.
-- Existing ingredient quantities and movement history are preserved.

ALTER TABLE POS_INGREDIENT
  DROP CONSTRAINT CK_POS_ING_STOCK;

ALTER TABLE POS_INGREDIENT_MOVEMENT
  DROP CONSTRAINT CK_POS_ING_MOV_STOCK;
