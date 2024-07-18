-- Step 1: Calculate the cost of goods sold (COGS) using FIFO
-- Create a temporary table to store the running total of sold quantities and their costs
CREATE TEMPORARY TABLE fifo_costs (
    sale_id INT,
    purchase_id INT,
    quantity INT,
    cost DECIMAL(10, 2)
);

-- Initialize the temporary table with sales and their matching purchase costs using FIFO
INSERT INTO fifo_costs (sale_id, purchase_id, quantity, cost)
SELECT 
    s.id AS sale_id,
    p.id AS purchase_id,
    LEAST(p.quantity - IFNULL((SELECT SUM(fc.quantity) FROM fifo_costs fc WHERE fc.purchase_id = p.id), 0), s.quantity) AS quantity,
    LEAST(p.quantity - IFNULL((SELECT SUM(fc.quantity) FROM fifo_costs fc WHERE fc.purchase_id = p.id), 0), s.quantity) * p.purchase_price AS cost
FROM 
    sales s
JOIN 
    purchases p ON p.id = (
        SELECT id FROM purchases WHERE (purchases.quantity - IFNULL((SELECT SUM(fc.quantity) FROM fifo_costs fc WHERE fc.purchase_id = purchases.id), 0)) > 0 ORDER BY purchase_date LIMIT 1
    )
WHERE 
    s.quantity > 0
ORDER BY 
    s.sale_date, p.purchase_date;

-- Step 2: Calculate the total sales revenue and total cost of goods sold
SELECT 
    SUM(s.quantity * s.sale_price) AS total_revenue,
    SUM(fc.cost) AS total_cogs,
    SUM(s.quantity * s.sale_price) - SUM(fc.cost) AS total_profit
FROM 
    sales s
JOIN 
    fifo_costs fc ON s.id = fc.sale_id;

-- Clean up: Drop the temporary table
DROP TEMPORARY TABLE fifo_costs;
