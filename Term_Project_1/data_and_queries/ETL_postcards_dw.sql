USE postcards;

DROP PROCEDURE IF EXISTS postcards_dw;
DELIMITER $$
CREATE PROCEDURE postcards_dw()
BEGIN
	-- unfortunately the stored procedures can't take table names as parameters, therefore the cleaning has to be executed for each eBay table...

	-- clean and aggregate on original order level: German eBay
	DROP TABLE IF EXISTS DE_temp;
	CREATE TABLE DE_temp AS 
    SELECT DISTINCT * 
    FROM
		(SELECT 
			a.standard_name,
			c.`name` as Customer,
			a.country as country, 
			o.total as total, 
			SUM(l.price*l.qty) as base_total, 
			IF((o.total - SUM(l.price*l.qty)) < 0 , 0, (o.total - SUM(l.price*l.qty)) ) as postage_and_tax, 
			IF((o.total - SUM(l.price*l.qty)) < 0 , (o.total - SUM(l.price*l.qty)) , 0 ) as correction, 
			SUM(l.qty) as quantity, 
			o.currency, 
			r.rate, 
			s.shipping_day 
		FROM de_orders as o
		INNER JOIN de_address as a ON a.address_id = o.shipping_address_id 
		INNER JOIN de_sold_listings as l ON o.sale_id = l.sale_id 
		INNER JOIN eur_usd_rates as r ON o.sales_date = r.`date` 
		INNER JOIN shipping_days as s ON o.sales_date = s.sales_date
		INNER JOIN Customers as c ON a.standard_name = c.standard_name
		INNER JOIN (SELECT DISTINCT sale_id, SUM(IF(MOD(x.price,1) = 0 , 1 , 0)) as lotcont fROM de_sold_listings x GROUP BY x.sale_id) as a ON o.sale_id = a.sale_id
		WHERE (o.sales_date BETWEEN '2020-11-30'AND '2021-10-28')
		AND a.lotcont = 0
		GROUP BY o.sale_id) d
	WHERE d.base_total + d.correction > 2;

	-- aggregate on real order level: German eBay
	DROP TABLE IF EXISTS DE_norm;
	CREATE TABLE DE_norm AS 
	SELECT 
		'DE' as sales_channel,
		standard_name,
		Customer, 
		country,
		sum(IF(currency = 'EUR', total , total/rate)) as total,
		sum(IF(currency = 'EUR', base_total , base_total/rate)) as base_total,
		sum(IF(currency = 'EUR', postage_and_tax , postage_and_tax/rate)) as postage_and_tax,
		sum(IF(currency = 'EUR', correction , correction/rate)) as correction,
		sum(quantity) as quantity,
		shipping_day
	FROM DE_temp
	group by shipping_day, standard_name;
	DROP TABLE IF EXISTS DE_temp;

	-- clean and aggregate on original order level: American eBay
	DROP TABLE IF EXISTS us_temp;
	CREATE TABLE us_temp AS
    SELECT DISTINCT *
    FROM
		(SELECT 
			a.standard_name,
			c.`name` as Customer,
			a.country as country, 
			o.total as total, 
			SUM(l.price*l.qty) as base_total, 
			IF((o.total - SUM(l.price*l.qty)) < 0 , 0, (o.total - SUM(l.price*l.qty)) ) as postage_and_tax, 
			IF((o.total - SUM(l.price*l.qty)) < 0 , (o.total - SUM(l.price*l.qty)) , 0 ) as correction, 
			SUM(l.qty) as quantity, 
			o.currency, 
			r.rate, 
			s.shipping_day 
		FROM us_orders as o
		INNER JOIN us_address as a ON a.address_id = o.shipping_address_id 
		INNER JOIN us_sold_listings as l ON o.sale_id = l.sale_id 
		INNER JOIN eur_usd_rates as r ON o.sales_date = r.`date` 
		INNER JOIN shipping_days as s ON o.sales_date = s.sales_date
		INNER JOIN Customers as c ON a.standard_name = c.standard_name
		WHERE (o.sales_date BETWEEN '2020-11-30'AND '2021-10-28')
		GROUP BY o.sale_id) d
	WHERE d.base_total + d.correction > 2;

	-- aggregate on real order level: American eBay
	DROP TABLE IF EXISTS us_norm;
	CREATE TABLE us_norm AS 
	SELECT 
		'US' as sales_channel,
		standard_name,
		Customer, 
		country,
		sum(IF(currency = 'EUR', total , total/rate)) as total,
		sum(IF(currency = 'EUR', base_total , base_total/rate)) as base_total,
		sum(IF(currency = 'EUR', postage_and_tax , postage_and_tax/rate)) as postage_and_tax,
		sum(IF(currency = 'EUR', correction , correction/rate)) as correction,
		sum(quantity) as quantity,
		shipping_day
	FROM us_temp
	group by shipping_day, standard_name;
	DROP TABLE IF EXISTS us_temp;

	-- clean and aggregate on original order level: French eBay
	DROP TABLE IF EXISTS fr_temp;
	CREATE TABLE fr_temp AS 
    SELECT DISTINCT *
    FROM	
		(SELECT 
			a.standard_name,
			c.`name` as Customer,
			a.country as country, 
			o.total as total, 
			SUM(l.price*l.qty) as base_total, 
			IF((o.total - SUM(l.price*l.qty)) < 0 , 0, (o.total - SUM(l.price*l.qty)) ) as postage_and_tax, 
			IF((o.total - SUM(l.price*l.qty)) < 0 , (o.total - SUM(l.price*l.qty)) , 0 ) as correction, 
			SUM(l.qty) as quantity, 
			o.currency, 
			r.rate, 
			s.shipping_day 
		FROM fr_orders as o
		INNER JOIN fr_address as a ON a.address_id = o.shipping_address_id 
		INNER JOIN fr_sold_listings as l ON o.sale_id = l.sale_id 
		INNER JOIN eur_usd_rates as r ON o.sales_date = r.`date` 
		INNER JOIN shipping_days as s ON o.sales_date = s.sales_date
		INNER JOIN Customers as c ON a.standard_name = c.standard_name
		INNER JOIN (SELECT DISTINCT sale_id, SUM(IF(MOD(x.price,1) = 0 , 1 , 0)) as lotcont FROM fr_sold_listings x GROUP BY x.sale_id) as a ON o.sale_id = a.sale_id
		WHERE (o.sales_date BETWEEN '2020-11-30'AND '2021-10-28')
		AND a.lotcont = 0
		GROUP BY o.sale_id) d
	WHERE d.base_total + d.correction > 2;

	-- aggregate on real order level: French eBay
	DROP TABLE IF EXISTS fr_norm;
	CREATE TABLE fr_norm AS 
	SELECT 
		'FR' as sales_channel,
		standard_name,
		Customer, 
		country,
		sum(IF(currency = 'EUR', total , total/rate)) as total,
		sum(IF(currency = 'EUR', base_total , base_total/rate)) as base_total,
		sum(IF(currency = 'EUR', postage_and_tax , postage_and_tax/rate)) as postage_and_tax,
		sum(IF(currency = 'EUR', correction , correction/rate)) as correction,
		sum(quantity) as quantity,
		shipping_day
	FROM fr_temp
	group by shipping_day, standard_name;
	DROP TABLE IF EXISTS fr_temp;

	-- clean and aggregate on original order level: HipPostcard
	DROP TABLE IF EXISTS hip_temp;
	CREATE TABLE hip_temp AS 
	SELECT DISTINCT *
    FROM	
		(SELECT 
			a.standard_name,
			c.`name` as Customer,
			a.country as country, 
			o.total + postage as total, 
			SUM(l.price*l.qty) as base_total,
			postage as postage_and_tax,
			o.total - SUM(l.price*l.qty) as correction,
			SUM(l.qty) as quantity, 
			o.currency, 
			r.rate, 
			s.shipping_day 
		FROM hip_orders as o
		INNER JOIN hip_address as a ON a.address_id = o.shipping_address_id 
		INNER JOIN hip_sold_listings as l ON o.sale_id = l.sale_id 
		INNER JOIN eur_usd_rates as r ON o.sales_date = r.`date` 
		INNER JOIN shipping_days as s ON o.sales_date = s.sales_date
		INNER JOIN Customers as c ON a.standard_name = c.standard_name
		INNER JOIN (SELECT DISTINCT sale_id, SUM(IF(MOD(x.price,1) = 0 , 1 , 0)) as lotcont FROM hip_sold_listings x GROUP BY x.sale_id) as a ON o.sale_id = a.sale_id
		WHERE (o.sales_date BETWEEN '2020-11-30'AND '2021-10-28')
		AND a.lotcont = 0
		GROUP BY o.sale_id) d
	WHERE d.base_total + d.correction > 2;

	-- aggregate on real order level: HipPostcard
	DROP TABLE IF EXISTS hip_norm;
	CREATE TABLE hip_norm AS 
	SELECT 
		'HIP' as sales_channel,
		standard_name,
		Customer, 
		country,
		sum(IF(currency = 'EUR', total , total/rate)) as total,
		sum(IF(currency = 'EUR', base_total , base_total/rate)) as base_total,
		sum(IF(currency = 'EUR', postage_and_tax , postage_and_tax/rate)) as postage_and_tax,
		sum(IF(currency = 'EUR', correction , correction/rate)) as correction,
		sum(quantity) as quantity,
		shipping_day
	FROM hip_temp
	group by shipping_day, standard_name;
	DROP TABLE IF EXISTS hip_temp;

	-- aggregate Delcampe and construct order level
	DROP TABLE IF EXISTS dc_norm;
	CREATE TABLE dc_norm AS
	SELECT DISTINCT *
    FROM	
		(SELECT 
			'Dc' as sales_channel,
			dc.standard_name as standard_name,
			c.`name` as Customer,
			dc.country as Country,
			IF(SUM(dc.qty*dc.price) > 70 , (SUM(dc.qty*dc.price) + 7 ) , (SUM(dc.qty*dc.price) + 2 ) ) as total,
			SUM(dc.qty*dc.price) as base_total,
			IF(SUM(dc.qty*dc.price) > 70 , 7 , 2 ) as postage_and_tax,
			0 as correction,
			SUM(dc.qty) as quantity,
			s.shipping_day as shipping_day
		FROM dc_sales dc
		INNER JOIN shipping_days as s ON dc.sales_date = s.sales_date
		INNER JOIN Customers as c ON dc.standard_name = c.standard_name
		WHERE (dc.sales_date BETWEEN '2020-11-30'AND '2021-10-28')
		GROUP BY s.shipping_day, dc.standard_name) d
	WHERE d.base_total + d.correction > 2;

	-- create data warehouse
	DROP TABLE IF EXISTS dw_postcards;
	CREATE TABLE dw_postcards AS
		SELECT * FROM (
			SELECT * FROM de_norm
			UNION ALL
			SELECT * FROM us_norm
			UNION ALL
			SELECT * FROM fr_norm
			UNION ALL
			SELECT * FROM hip_norm
			UNION ALL
			SELECT * FROM dc_norm) v;
	
    -- fix ugly decimals
	ALTER TABLE dw_postcards
		MODIFY total decimal(14,2),
        MODIFY base_total decimal(14,2),
        MODIFY correction decimal(14,2),
        MODIFY postage_and_tax decimal(14,2);

	-- delete unnecessary tables 
	DROP TABLE IF EXISTS de_norm;
	DROP TABLE IF EXISTS fr_norm;
	DROP TABLE IF EXISTS us_norm;
	DROP TABLE IF EXISTS dc_norm;
	DROP TABLE IF EXISTS hip_norm;

END;
$$
DELIMITER ;


CALL postcards_dw();