
USE bookstore_db;


-- -- Query 1

SELECT 
    b.title AS book_title, 
    b.isbn AS book_isbn, 
    CONCAT(a.first_name, ' ', a.last_name) AS author_name
FROM 
    books b
JOIN 
    book_authors ba ON b.book_id = ba.book_id
JOIN 
    authors a ON ba.author_id = a.author_id;



-- -- Query 2
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    o.order_date AS order_date,
    b.title AS book_title,
    od.quantity AS order_quantity,
    (od.quantity * od.unit_price) AS line_total
FROM 
    orders o
JOIN 
    customers c ON o.customer_id = c.customer_id
JOIN 
    order_details od ON o.order_id = od.order_id
JOIN 
    books b ON od.book_id = b.book_id
ORDER BY 
    o.order_date DESC;




-- -- Query 3
SELECT 
    b.title AS book_title,
    p.name AS publisher_name,
    GROUP_CONCAT(cat.name SEPARATOR ', ') AS book_categories
FROM 
    books b
JOIN 
    publishers p ON b.publisher_id = p.publisher_id
JOIN 
    book_categories bc ON b.book_id = bc.book_id
JOIN 
    categories cat ON bc.category_id = cat.category_id
GROUP BY 
    b.book_id, b.title, p.name;



-- -- Query 4
SELECT 
    b.title AS book_title,
    COALESCE(SUM(od.quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(od.quantity * od.unit_price), 0.00) AS total_revenue
FROM 
    books b
LEFT JOIN 
    order_details od ON b.book_id = od.book_id
GROUP BY 
    b.book_id, b.title
ORDER BY 
    total_revenue DESC;



-- -- Query 5
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS num_orders,
    COALESCE(SUM(od.quantity * od.unit_price), 0.00) AS total_amount_spent
FROM 
    customers c
LEFT JOIN 
    orders o ON c.customer_id = o.customer_id
LEFT JOIN 
    order_details od ON o.order_id = od.order_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name;




-- -- Query 6
SELECT 
    title AS book_title, 
    price AS book_price
FROM 
    books
WHERE 
    price > (SELECT AVG(price) FROM books);



-- -- Query 7
SELECT 
    CONCAT(a.first_name, ' ', a.last_name) AS author_name,
    t1.total_sold
FROM (
    SELECT ba.author_id, SUM(od.quantity) AS total_sold
    FROM book_authors ba
    JOIN order_details od ON ba.book_id = od.book_id
    GROUP BY ba.author_id
) t1
JOIN authors a ON t1.author_id = a.author_id
WHERE t1.total_sold = (
    SELECT MAX(total_author_sales)
    FROM (
        SELECT SUM(od2.quantity) AS total_author_sales
        FROM book_authors ba2
        JOIN order_details od2 ON ba2.book_id = od2.book_id
        GROUP BY ba2.author_id
    ) t2
);




-- -- Query 8
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(r.review_id) AS qualifying_reviews
FROM 
    customers c
JOIN 
    reviews r ON c.customer_id = r.customer_id
WHERE 
    r.rating >= 3
GROUP BY 
    c.customer_id, c.first_name, c.last_name
HAVING 
    qualifying_reviews > 2;

-- -- Query 9
CREATE OR REPLACE VIEW v_book_sales_summary AS
SELECT 
    b.title AS book_title,
    b.isbn AS book_isbn,
    p.name AS publisher_name,
    COALESCE(t_sales.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(t_sales.total_revenue, 0.00) AS total_revenue,
    t_reviews.average_rating AS average_review_rating,
    t_reviews.num_reviews AS number_of_reviews
FROM 
    books b
JOIN 
    publishers p ON b.publisher_id = p.publisher_id
LEFT JOIN (
    SELECT book_id, SUM(quantity) AS total_quantity_sold, SUM(quantity * unit_price) AS total_revenue
    FROM order_details
    GROUP BY book_id
) t_sales ON b.book_id = t_sales.book_id
LEFT JOIN (
    SELECT book_id, AVG(rating) AS average_rating, COUNT(review_id) AS num_reviews
    FROM reviews
    GROUP BY book_id
) t_reviews ON b.book_id = t_reviews.book_id;

-- Select from the created view to demonstrate it works
SELECT 
    book_title, 
    book_isbn, 
    publisher_name, 
    total_quantity_sold, 
    total_revenue, 
    average_review_rating, 
    number_of_reviews 
FROM 
    v_book_sales_summary 
LIMIT 5;




-- -- Query 10
SELECT 
    m.month_num AS month_number,
    m.month_name AS month_name,
    COALESCE(rs.num_orders, 0) AS num_orders,
    COALESCE(rs.items_sold, 0) AS total_items_sold,
    COALESCE(rs.monthly_revenue, 0.00) AS total_revenue
FROM (
    SELECT 1 AS month_num, 'January' AS month_name UNION SELECT 2, 'February' UNION SELECT 3, 'March' 
    UNION SELECT 4, 'April' UNION SELECT 5, 'May' UNION SELECT 6, 'June' 
    UNION SELECT 7, 'July' UNION SELECT 8, 'August' UNION SELECT 9, 'September' 
    UNION SELECT 10, 'October' UNION SELECT 11, 'November' UNION SELECT 12, 'December'
) m
LEFT JOIN (
    SELECT 
        MONTH(o.order_date) AS order_month, 
        COUNT(DISTINCT o.order_id) AS num_orders,
        SUM(od.quantity) AS items_sold,
        SUM(od.quantity * od.unit_price) AS monthly_revenue
    FROM 
        orders o
    JOIN 
        order_details od ON o.order_id = od.order_id
    WHERE 
        YEAR(o.order_date) = YEAR(CURDATE())
    GROUP BY 
        MONTH(o.order_date)
) rs ON m.month_num = rs.order_month;

