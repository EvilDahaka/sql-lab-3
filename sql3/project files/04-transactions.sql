BEGIN;

INSERT INTO readers (first_name, last_name, email, phone, library_card_number)
VALUES ('Анна', 'Романенко', 'anna@library.com', '+380931111222', 'LIB-011');

UPDATE readers
SET status = 'Active'
WHERE email = 'anna@library.com';

COMMIT;