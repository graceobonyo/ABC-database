CREATE DATABASE abcDB;
USE abcDB;

USE abcDB;
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_customers_email (email)
);

USE abcDB;
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT KEY ft_products_name (product_name)
);

USE abcDB;
CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    region VARCHAR(50),
    order_status VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_orders_order_date (order_date),
    INDEX idx_orders_customer_id (customer_id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
) ;


USE abcDB;
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order_items_order_product (order_id, product_id),
    INDEX idx_order_items_product_id (product_id),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
);

USE abcDB;


# INDEX ON ORDER
USE abcDB;
CREATE INDEX idx_orders_order_date
ON orders (order_date);

# COMPOSITE INDEX
USE abcDB;
CREATE INDEX idx_order_items_order_product
ON order_items (order_id, product_id);

# UNIQUE INDEX
USE abcDB;
ALTER TABLE customers
ADD UNIQUE INDEX uq_customers_email (email);

# FULL TEXT INDEX
USE abcDB;
ALTER TABLE products
ADD FULLTEXT INDEX ft_products_name (product_name);

# ANALYZE INDEX USAGE 
USE abcDB;
EXPLAIN
SELECT o.order_id, o.order_date, c.customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date >= '2024-01-01';

# RANGE PARTITIONING
USE abcDB;
ALTER TABLE orders
PARTITION BY RANGE (YEAR(order_date)) (
  PARTITION p2023 VALUES LESS THAN (2024),
  PARTITION p2024 VALUES LESS THAN (2025),
  PARTITION p_future VALUES LESS THAN MAXVALUE
);

# LIST PARTITIONING
USE abcDB;
ALTER TABLE orders
ADD COLUMN region VARCHAR(50);


# HASH PARTITIONING
USE abcDB;
SELECT PARTITION_NAME, TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_NAME = 'customers';

# OPTIMIZING HEAVY JOIN QUERRY
USE abcDB;
SELECT c.customer_id,
       SUM(oi.quantity * oi.unit_price) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id;

# OPTIMIZING QUANTITY AND REVENUE PER PRODUCT
USE abcDB;
SELECT p.product_id,
       p.product_name,
       SUM(oi.quantity) AS total_quantity,
       SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name;

# OPTIMIZING DATE FILTERS
USE abcDB;
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
       COUNT(*) AS total_orders
FROM orders
GROUP BY order_month;

# COMBINED PERFORMANCE QUERRY
USE abcDB;
SELECT c.customer_id,
       COUNT(DISTINCT o.order_id) AS total_orders,
       SUM(oi.quantity) AS total_quantity,
       SUM(oi.quantity * oi.unit_price) AS total_spent
FROM customers c
JOIN orders o
  ON c.customer_id = o.customer_id
JOIN order_items oi
  ON o.order_id = oi.order_id
GROUP BY c.customer_id;