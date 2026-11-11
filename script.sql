-- ============================================================
-- Оконные функции. Задание 1 (PostgreSQL)
-- ============================================================

-- ---------- Схема и тестовые данные ----------
CREATE SCHEMA IF NOT EXISTS hr_poc;

DROP TABLE IF EXISTS hr_poc.employees;
CREATE TABLE hr_poc.employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50)   NOT NULL,
    last_name     VARCHAR(50)   NOT NULL,
    department_id INT           NOT NULL,
    salary        NUMERIC(10,2) NOT NULL
);

INSERT INTO hr_poc.employees (first_name, last_name, department_id, salary) VALUES
('Иван',   'Петров',   10, 100000),
('Анна',   'Сидорова', 10, 150000),
('Олег',   'Иванов',   10, 150000),
('Мария',  'Козлова',  20,  80000),
('Сергей', 'Орлов',    20,  95000),
('Елена',  'Волкова',  30,  70000),
('Павел',  'Зайцев',   30,  70000),
('Дарья',  'Попова',   30,  90000);

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT  NOT NULL,
    order_date  DATE NOT NULL
);
CREATE TABLE order_items (
    item_id    SERIAL PRIMARY KEY,
    order_id   INT           NOT NULL REFERENCES orders(order_id),
    product_id INT           NOT NULL,
    quantity   INT           NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL
);

INSERT INTO orders (customer_id, order_date) VALUES (1,'2026-11-01'),(2,'2026-11-02'),(1,'2026-11-05');
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1,101,2,10.00),(1,102,1,5.50),
(2,101,3,10.00),
(3,103,1,99.90),(3,102,4,5.50);

DROP TABLE IF EXISTS transport;
CREATE TABLE transport(train_id INT, station VARCHAR(30), time_arrival TIME);
INSERT INTO transport VALUES
(110, 'СПБ',      '10:00:00'),
(110, 'Ланская',  '10:54:00'),
(110, 'Удельная', '11:02:00'),
(110, 'Шувалово', '12:35:00'),
(120, 'СПБ',      '11:00:00'),
(120, 'Удельная', '11:54:00'),
(120, 'Рощино',   '12:04:00'),
(120, 'Выборг',   '13:03:00');

-- ---------- 1. Нумерация всех строк ----------
SELECT ROW_NUMBER() OVER (ORDER BY employee_id) AS rn, e.*
FROM hr_poc.employees e;

-- ---------- 2. Нумерация сотрудников по отделам ----------
SELECT department_id, employee_id,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY employee_id) AS rn_in_dept
FROM hr_poc.employees
ORDER BY department_id, rn_in_dept;

-- ---------- 3. Позиция по зарплате в отделе ----------
SELECT department_id, employee_id, salary,
       RANK()       OVER w AS salary_rank,
       DENSE_RANK() OVER w AS salary_dense_rank
FROM hr_poc.employees
WINDOW w AS (PARTITION BY department_id ORDER BY salary DESC)
ORDER BY department_id, salary_rank;

-- ---------- 4. Разница со средней и максимальной по отделу ----------
SELECT department_id, employee_id, salary,
       ROUND(AVG(salary) OVER (PARTITION BY department_id), 2)           AS avg_salary,
       ROUND(salary - AVG(salary) OVER (PARTITION BY department_id), 2) AS diff_from_avg,
       MAX(salary) OVER (PARTITION BY department_id)                    AS max_salary,
       salary - MAX(salary) OVER (PARTITION BY department_id)           AS diff_from_max
FROM hr_poc.employees
ORDER BY department_id, salary DESC;

-- ---------- 5. Стоимость каждого заказа ----------
SELECT order_id, product_id,
       quantity * unit_price AS line_cost,
       SUM(quantity * unit_price) OVER (PARTITION BY order_id) AS order_cost
FROM order_items
ORDER BY order_id, item_id;

-- ---------- 6. Время до следующей станции (LEAD) ----------
SELECT train_id, station,
       time_arrival AS "Прибытие на станцию",
       LEAD(time_arrival) OVER (PARTITION BY train_id ORDER BY time_arrival)
         - time_arrival AS "Время до станции"
FROM transport
ORDER BY train_id, time_arrival;

-- ---------- 7. Полное время поездки до текущей станции (FIRST_VALUE) ----------
SELECT train_id, station,
       time_arrival AS "Прибытие на станцию",
       time_arrival - FIRST_VALUE(time_arrival) OVER w AS "Прошедшее время",
       LEAD(time_arrival) OVER w - time_arrival        AS "Время до станции"
FROM transport
WINDOW w AS (PARTITION BY train_id ORDER BY time_arrival)
ORDER BY train_id, time_arrival;
