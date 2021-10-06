-- HW4 - Endes-Nagy Peter
-- Assuming that you have the classicmodels database available
USE classicmodels;

-- INNER join orders,orderdetails,products and customers and list (...)
SELECT o.orderNumber, o.orderDate, 
	od.priceEach, od.quantityOrdered, 
	p.productName, p.productLine, 
	c.city, c.country
FROM orderdetails od
	INNER JOIN orders o 
		ON od.OrderNumber = o.OrderNumber
	INNER JOIN products p 
		ON od.ProductCode = p.ProductCode
	INNER JOIN customers c 
		ON o.CustomerNumber = c.CustomerNumber;