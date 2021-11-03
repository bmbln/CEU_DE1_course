USE postcards;

-- TOP 20 largest customers of the last year
DROP PROCEDURE IF EXISTS largest_customers;
DELIMITER $$
CREATE PROCEDURE largest_customers()
BEGIN
    DROP VIEW IF EXISTS largest_customers;
	CREATE VIEW largest_customers AS
		SELECT 
			m.Customer,
			m.country as `Country`,
			concat(CAST(m.total AS DECIMAL(14,0)),' EUR') AS `Total value of orders`,
			concat(CAST(m.avg_order AS DECIMAL(14,1)),' EUR') AS `Average value of orders`,
			concat(CAST(m.avg_price AS DECIMAL(14,2)),' EUR') AS `Average price of purchased postcards`,
			m.no_item as `Number of purchased postcards`,
			concat(CAST(m.total/(SELECT sum(base_total + correction) FROM dw_postcards)*100 AS decimal(14,2)),'%') as `share in total sales`
				FROM (
					SELECT
						w.Customer as Customer,
						sum((w.base_total + w.correction)) as total,
						avg((w.base_total + w.correction)) as avg_order,
						sum(w.base_total)/sum(w.quantity) as avg_price,
						w.country as country,
						sum(w.quantity) as no_item
					FROM dw_postcards w
					GROUP BY w.Customer
					ORDER BY total DESC) m
		LIMIT 20;
SELECT * FROM largest_customers;
END;
$$
DELIMITER ;

CALL largest_customers();



-- TOP markets of last year ordered by total values of orders
DROP PROCEDURE IF EXISTS largest_markets;
DELIMITER $$
CREATE PROCEDURE largest_markets()
BEGIN
	DROP VIEW IF EXISTS largest_markets;
	CREATE VIEW largest_markets AS
		SELECT 
			m.country as `Country`,
			concat(CAST(m.total AS DECIMAL(14,0)),' EUR') AS `Total value of orders`,
			m.no_item as `Number of purchased postcards`,
			m.no_order as `Number of orders`,
			concat(CAST(m.avg_order AS DECIMAL(14,1)),' EUR') AS `Average value of orders`,
			concat(CAST(m.avg_price AS DECIMAL(14,2)),' EUR') AS `Average price of purchased postcards`,
			concat(CAST(m.max_order AS DECIMAL(14,1)),' EUR') AS `Largest order value`,
			concat(CAST(m.total/(SELECT sum(base_total + correction) FROM dw_postcards)*100 AS decimal(14,2)),'%') as `Share in total sales`,
			concat(CAST(m.no_item/(SELECT sum(quantity) FROM dw_postcards)*100 AS decimal(14,2)),'%') as `Share in purchased cards`,
			concat(CAST(m.no_order/(SELECT count(sales_channel) FROM dw_postcards)*100 AS decimal(14,2)),'%') as `Share in order number`
			FROM (
				SELECT 
					w.country as country,
					sum((w.base_total + w.correction)) as total,
					avg((w.base_total + w.correction)) as avg_order,
					sum(w.base_total)/sum(w.quantity) as avg_price,
					sum(w.quantity) as no_item,
					max((w.base_total + w.correction)) as max_order,
					count(w.sales_channel) as no_order
				FROM dw_postcards w
				GROUP BY w.country
				ORDER BY w.total DESC) m
		ORDER BY m.total DESC;
	SELECT * FROM largest_markets; 
END;
$$
DELIMITER ;

CALL largest_markets();

-- Order size and share of single card orders
DROP PROCEDURE IF EXISTS order_size;
DELIMITER $$
CREATE PROCEDURE order_size()
BEGIN
	DROP VIEW IF EXISTS order_size;
	CREATE VIEW order_size AS
		SELECT
			m.qty_type as `Order size category`,
			concat(cast(SUM(m.ototal) AS DECIMAL(14,0)),' EUR') as `Total value of orders`,
			COUNT(m.qty_type) as `Number of orders`,
			concat(cast(
				SUM(m.ototal)/(SELECT sum(w.base_total + w.correction) FROM dw_postcards w)*100
				AS DECIMAL(14,2)),'%') as `Share in total value`,
			concat(cast(
				COUNT(m.qty_type)/(SELECT COUNT(w.sales_channel) FROM dw_postcards w)*100
				AS DECIMAL(14,2)),'%') as `Share in order number`,    
			concat(cast(AVG(m.ototal) AS DECIMAL(14,2)),' EUR') as `Average order value`,
			concat(cast(min(m.ototal) AS DECIMAL(14,2)),' EUR') as `Smalles order size`,
			concat(cast(max(m.ototal) AS DECIMAL(14,2)),' EUR') as `Largest ordersize`
		FROM
			(SELECT 
				(w.base_total + w.correction) as ototal,
				IF(w.quantity = 1,'1', 
					IF(w.quantity > 1 AND w.quantity < 6 , '2-5', 
						IF(w.quantity > 6 AND w.quantity < 11 , '6-10','11+'))) as qty_type
			FROM dw_postcards w) m
		GROUP BY m.qty_type;
	SELECT * FROM order_size;
END;
$$
DELIMITER ;

CALL order_size();