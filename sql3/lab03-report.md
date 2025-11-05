# Звіт з лабораторної роботи 3. Модифікація даних та транзакції

**Виконав:** Лешо Давид
**Група:** 32
**Дата виконання:** 5 Листопада 2025 року
**Варіант:** Система управління бібліотекою

## Мета роботи

Здобути практичні навички безпечної модифікації даних у реляційних базах даних, опанувати механізми транзакцій для забезпечення цілісності даних, навчитися працювати з обмеженнями цілісності та каскадними операціями при зміні взаємопов'язаних записів.

## Виконання роботи

### Рівень 1. Базові операції модифікації

#### Крок 1. Створення структури бази даних

Створено базу даних для системи управління бібліотекою з чотирма основними таблицями.

```sql
CREATE DATABASE library_db;
```

**Таблиця авторів з обмеженнями:**

```sql
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year INTEGER CHECK (birth_year >= 1000 AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Обмеження таблиці authors:
- PRIMARY KEY на author_id забезпечує унікальність кожного автора.
- NOT NULL на іменах запобігає створенню анонімних авторів.
- CHECK на birth_year обмежує діапазон коректних років народження.

**Таблиця книг з розширеними обмеженнями:**

```sql
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    isbn VARCHAR(17) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    author_id INTEGER NOT NULL,
    publication_year INTEGER CHECK (publication_year >= 1450),
    genre VARCHAR(50),
    total_copies INTEGER DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INTEGER DEFAULT 1 CHECK (available_copies >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE RESTRICT,
    CHECK (available_copies <= total_copies)
);
```

Ключові обмеження:
- UNIQUE на isbn гарантує відсутність дублікатів книг.
- FOREIGN KEY з ON DELETE RESTRICT запобігає видаленню авторів, у яких є книги.
- CHECK для available_copies <= total_copies забезпечує логічну консистентність.

**Таблиця читачів:**

```sql
CREATE TABLE readers (
    reader_id SERIAL PRIMARY KEY,В
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    library_card_number VARCHAR(20) UNIQUE NOT NULL,
    registration_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Blocked', 'Inactive'))
);
```

**Таблиця видач:**

```sql
CREATE TABLE lendings (
    lending_id SERIAL PRIMARY KEY,
    book_id INTEGER NOT NULL,
    reader_id INTEGER NOT NULL,
    lending_date DATE DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE RESTRICT,
    FOREIGN KEY (reader_id) REFERENCES readers(reader_id) ON DELETE RESTRICT,
    CHECK (due_date > lending_date),
    CHECK (return_date IS NULL OR return_date >= lending_date)
);;
```

**Результат створення структури:**

![Створення таблиць](<screenshots/1-Створення бд.png>)

#### Крок 1. Додавання тестових даних

Виконано вставку початкових даних у всі створені таблиці.

**Додавання авторів:**

```sql
INSERT INTO authors (first_name, last_name, birth_year, country)
VALUES
('Ліна', 'Костенко', 1930, 'Україна'),
('Василь', 'Стус', 1938, 'Україна'),
('Оксана', 'Забужко', 1960, 'Україна'),
('Іван', 'Франко', 1856, 'Україна'),
('Тарас', 'Шевченко', 1814, 'Україна'),
('Леся', 'Українка', 1871, 'Україна'),
('Григорій', 'Сковорода', 1722, 'Україна'),
('Юрій', 'Андрухович', 1960, 'Україна'),
('Сергій', 'Жадан', 1974, 'Україна'),
('Марко', 'Вовчок', 1833, 'Україна');
```

**Результат вставки:**

```
10 rows inserted
```

**Перевірка доданих авторів:**

```sql
SELECT * FROM authors ORDER BY birth_year;
```

![Перевірка даних](<screenshots/4-Перевірка доданих авторів.png>)

**Додавання книг:**

```sql
INSERT INTO books (isbn, title, author_id, publication_year, genre, total_copies, available_copies)
VALUES
('978-617-7585-05-9', 'Маруся Чурай', 1, 1979, 'Історичний роман', 8, 8),
('978-966-508-651-7', 'Дорога болю', 2, 1990, 'Поезія', 6, 6),
('978-617-679-434-5', 'Польові дослідження українського сексу', 3, 1996, 'Проза', 4, 4),
('978-966-03-7968-1', 'Захар Беркут', 4, 1883, 'Історична повість', 5, 5),
('978-966-03-7988-9', 'Кобзар', 5, 1840, 'Поезія', 10, 10),
('978-966-03-7101-2', 'Лісова пісня', 6, 1911, 'Драма-феєрія', 7, 7),
('978-966-03-7655-0', 'Байки Харківські', 7, 1769, 'Філософія', 3, 3),
('978-617-585-032-1', 'Рекреації', 8, 1992, 'Постмодернізм', 5, 5),
('978-617-585-033-8', 'Ворошиловград', 9, 2010, 'Сучасна проза', 6, 6),
('978-966-03-7520-1', 'Інститутка', 10, 1859, 'Реалізм', 4, 4);
```

**Додавання читачів:**

```sql
INSERT INTO readers (first_name, last_name, email, phone, library_card_number)
VALUES
('Віктор', 'Кравчук', 'viktor@library.com', '+380962223344', 'LIB-001'),
('Наталія', 'Гончар', 'nataliya@library.com', '+380673334455', 'LIB-002'),
('Марія', 'Коваль', 'maria@library.com', '+380503336677', 'LIB-003'),
('Олександр', 'Семенюк', 'olex@library.com', '+380663331122', 'LIB-004'),
('Ірина', 'Ткаченко', 'iryna@library.com', '+380951112233', 'LIB-005'),
('Юрій', 'Мельник', 'yuriy@library.com', '+380931234567', 'LIB-006'),
('Світлана', 'Петренко', 'svitlana@library.com', '+380994445566', 'LIB-007'),
('Микола', 'Бондар', 'mykola@library.com', '+380675551212', 'LIB-008'),
('Олена', 'Литвин', 'olena@library.com', '+380685551717', 'LIB-009'),
('Петро', 'Кириленко', 'petro@library.com', '+380935551010', 'LIB-010');
```

![Додавання даних](<screenshots/3-Додавання даних.png>)

#### Крок 2. Безпечне оновлення записів (UPDATE з WHERE)

Це показує, як змінювати дані обережно — лише там, де потрібно
```sql
-- Змінити статус одного читача
UPDATE readers
SET status = 'Blocked'
WHERE library_card_number = 'LIB-002';

-- Зменшити кількість доступних копій у книги "Кобзар", бо її взяли
UPDATE books
SET available_copies = available_copies - 1
WHERE title = 'Кобзар';
```
--Перевірка
```sql
SELECT title, available_copies FROM books WHERE title = 'Кобзар';
SELECT first_name, last_name, status FROM readers WHERE library_card_number = 'LIB-002';
```
![Перевірка даних](<screenshots/8-Перевірка оновлення даних.png>)

#### Крок 3. Здійснити видалення записів з урахуванням зовнішніх ключів
Перевірка перед видаленням
```sql
--Спочатку перевір, чи читач не має активних видач (lendings):
SELECT l.lending_id, b.title, l.due_date
FROM lendings l
JOIN readers r ON l.reader_id = r.reader_id
JOIN books b ON l.book_id = b.book_id
WHERE r.library_card_number = 'LIB-002';
--Якщо запит повертає порожню таблицю — читача можна видаляти
```
Видалення без порушення зв'язків
```sql
DELETE FROM readers
WHERE library_card_number = 'LIB-002'
  AND reader_id NOT IN (
      SELECT reader_id FROM lendings
  );
```
Результат
```
1 row deleted
```


#### Крок 4. Використання транзакцій (BEGIN / COMMIT)

```sql
--Використання транзакцій (BEGIN / COMMIT)
BEGIN;

INSERT INTO readers (first_name, last_name, email, phone, library_card_number)
VALUES ('Анна', 'Романенко', 'anna@library.com', '+380931111222', 'LIB-011');

UPDATE readers
SET status = 'Active'
WHERE email = 'anna@library.com';

COMMIT;
```

![Використання транзакцій](<screenshots/6-Використання транзакцій .png>)

#### Крок 5. Демонстрація ROLLBACK

Демонстрація ROLLBACK при помилках
```sql
---Тут навмисно робимо помилку, щоб побачити, як ROLLBACK скасовує зміни

-- ця команда створить помилку, бо author_id = 999 не існує
INSERT INTO books (isbn, title, author_id, publication_year, genre)
VALUES ('999-9-9999-9999-9', 'Помилкова книга', 999, 2025, 'Фантастика');

-- ця команда не виконається через помилку вище
UPDATE books SET total_copies = 0 WHERE title = 'Помилкова книга';

ROLLBACK;
```
Результат
```
ERROR: insert або update в таблиці "books" порушує обмеження зовнішнього ключа "books_author_id_fkey"
```

![Демонстрація ROLLBACK](<screenshots/7-Демонстрація ROLLBACK.png>)


## Висновки

У результаті виконання лабораторної роботи здобуто практичні навички роботи з операціями модифікації даних у реляційних базах даних.

1. Створено повнофункціональну базу даних для системи управління бібліотекою з правильно визначеними обмеженнями цілісності.
2. Опановано безпечні методи виконання операцій INSERT, UPDATE та DELETE з обов'язковою попередньою перевіркою через SELECT.
3. Вивчено механізми транзакцій та їх властивості ACID. Продемонстровано використання BEGIN, COMMIT та ROLLBACK для забезпечення атомарності операцій.


## Посилання на проєкт

Репозиторій з повним кодом SQL скриптів: `https://github.com/EvilDahaka/sql-lab-3.git`

Файли проєкту:
- `01-create-structure.sql` - створення структури БД
- `02-insert-data.sql` - початкові дані
- `03-basic-operations.sql` - базові операції модифікації
- `04-transactions.sql` - робота з транзакціями
