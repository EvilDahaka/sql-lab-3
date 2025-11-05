--Безпечне оновлення записів (UPDATE з WHERE)




--Безпечне оновлення записів (UPDATE з WHERE)
-- Змінити статус одного читача
UPDATE readers
SET status = 'Blocked'
WHERE library_card_number = 'LIB-002';

-- Зменшити кількість доступних копій у книги "Кобзар", бо її взяли
UPDATE books
SET available_copies = available_copies - 1
WHERE title = 'Кобзар';

--Перевірка
SELECT title, available_copies FROM books WHERE title = 'Кобзар';
SELECT first_name, last_name, status FROM readers WHERE library_card_number = 'LIB-002';




--Видалення даних
SELECT l.lending_id, b.title, l.due_date
FROM lendings l
JOIN readers r ON l.reader_id = r.reader_id
JOIN books b ON l.book_id = b.book_id
WHERE r.library_card_number = 'LIB-002';
--Якщо запит повертає порожню таблицю — читача можна видаляти
DELETE FROM readers
WHERE library_card_number = 'LIB-002'
  AND reader_id NOT IN (
      SELECT reader_id FROM lendings
  );
