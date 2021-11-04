# Sales of vintage postcards – real dataset
I built a MySQL schema using the sales and stock database of a previous client of mine on vintage postcards.  

In this project, I’m planning to 
- identify large, returning Customers who are purchasing a lot, oftentimes via different sales channels  
- analyze market performance by countries   
- analyze order size  

## Data source – nature and challenges  
The merchant has been selling vintage postcards on different sales channels for 15 years.  
- eBay France since 2009  
- eBay.com since 2006  
- Delcampe since 2013  
- eBay Germany since 2019  
- HipPostcard since 2018  

**Business model**: purchasing collections then selling postcards as single items (re-classified into categories and scanned, uploaded 1 by 1). 
Freshly uploaded cards are usually hot sales then they remain in stock for years therefore the stock is gradually expanding. Sometimes items are sold a decade later. Some items are never going to be sold, sales rate is roughly 10-20% compared to the original stock size.  

In 2019, it was decided to set up a database in order to  
- keep the sales synchronized across different sales channels
- create a backup (item features and photos)
- create the foundation for an own web shop
- properly manage the stock (stock size increased from 200.000 to almost a million between 2017 and 2020)  

### Damaged databases  
The **creation** of the database happened **on the fly**; the database is messy and damaged for different reasons.  
| **Damage** |	**Reason**	| **Consequences** |
| :--- | :---------- | :---------- |
| Sales data unavailability | Creating backup and synchronization was prioritized. Sales data appeared with over a year of delay (different delay per sales platforms mostly due to difficulties with API calls and API limits on availability of historical data), no sales data prior to the database’s creation. | Sales data cannot be analyzed before the sales channels’ integration. <br> <br> Latest: 03/11/2020 (Hip), Earliest: 24/07/2019 (Delcampe) |  
| Incomplete stock data | Creation on the fly, the current active stock was retrieved by channels. <br><br> We have no data on postcards that have been in stock but sold anywhere before the databases’ creation date. <br><br> We also miss stock data from eBay.com because the shop was temporarily shut down for 2 years and started from scratch again in 2018. | Unreliable stock size data at given points of time |  
| Damaged stock data | Instead of revising the items, they were closed and reuploaded again. Oftentimes months have passed by between closing and re-uploading. | Unreliable item’s creation date. <br><br> Challenging calculation of stock size on given dates. <br><br> Stock size metric is unreliable in itself, rather “available number of listings” at a given point of time |  
| Ambigous item ID’s | Creation on the fly, item ID’s had to be constructed in order to connect stock data of different sales channels. <br><br> The postcards are unique items, a number is written at the end of each title that serves to identify the item physically in stock (written on the backside of the card with pencil) referred as `global_id` later. <br><br> These ID’s are ambiguous, there are rare double numberings (same number but different items), some ID’s had been reused (different item 2 years ago than now). | Stock data is split into 5 databases by sales channels, there is no single stock dataset (about the common item characteristics + which sales channels are they listed on.) <br> Due to different item characteristics by sales channels, it would be otherwise necessary to store listings in different tables. <br><br> The real item ID (number in the title and on the card in the physical stock) isn’t really unique.  |  
| Bad API’s | Sales channel data is retrieved via API’s. <br> Their reliability isn’t consistent, almost all of them produce errors, but of different types and magnitudes: delays, missing data (doesn’t communicate the data), etc. <br><br> They are also inconsistent with regards to information they provide, especially on sales | Missing and wrong data |  
| 6th channel items | There is a 6th channel for selling lots (not single postcards). <br> Some of these listings appear in the database although they should be treated differently | Wrong data (that shouldn’t be here) |  
  
It might be worth noting that the database is filled with unnecessary data and variables (while some key variables are missing) due to poor delivery by the IT supplier.  

### Partially overlapping stocks 

Different sales channels aren’t only used for broader accessibility of the items, but also for specialization purposes. Therefore, some items are listed on some platforms but aren’t on others. Due to listing mistakes, overlapping might be also incomplete even though it should exist.  

The underlying logic is that everything is listed on Delcampe and eBay France.  
- HipPostcard is an automatic copy of eBay France stock (incomplete copy due to poor performance of Hip’s own synchronization system). 
- eBay Germany was created as a narrowed down version of eBay France – items migrated from eBay France upon creation, later new items are listed there as well. 
- eBay.com is mainly used for auctions, this limited stock is later relisted as fixed price items on eBay.com and migrated to other sales channels every once in a few months. 
 
<p align="center">
  <img width="50%" src="https://github.com/bmbln/CEU_DE1_course/blob/335754ab55738b882c9d32d458803b2868e9a4d4/Term_Project_1/pictures/Overlapping%20stocks.PNG">
</p>

### Item and sales characteristics
We have different data on sales and item characteristics by sales channels. Compared to the central eBay France stock the main, relevant differences are as follows:  

| **Sales channel** |	**Item characteristics**	| **Sales data** |
| :--- | :---------- | :---------- |
| *eBay Germany* | item categories |  |  
| *eBay.com* | item categories <br><br> currency | shipping pricing <br><br> currency |  
| *HipPostcard* | item categories <br><br> sometimes currency <br><br> data structure | sometimes currency <br><br> data structure |  
| *Delcampe* | item categories <br><br> data structure | data structure <br><br> no status data (paid, shipped) <br><br> no information on shipping fee paid <br><br> no order level data (total, etc.) |  

An additional tricky feature is that buying on these sites has 2 main methods: putting the items into a cart or hit ‘buy it now’. The issue is that ‘buy it now’ creates single orders and charges the shipping fee each time, while using the cart regroups the purchases and reduces the shipping fee. There are many Customers unaware of this difference and hits ‘buy it now’ for each items, therefore the order databases are misleading – in the Delcampe database, we don’t even have order level data at all.  

To overcome the issue, order-levels are going to be recalculated on **“real” order level** upon creating the analytical layer based on shipping days: *the merchant ships on Mondays and Fridays. It brings slight bias in the data since the actual shipping days can be different on some occasions and the calculations are going to be biased for Delcampe orders as well (estimate of shipping paid/charged).* See more details under *Analytical layer*.   

### Dataset creation for the operational layer
The original database is split into four sub-databases by sales channels. I have private access in reading mode on a *phpMyAdmin* interface. 
The structure of the original operational layer is available [here](https://github.com/bmbln/CEU_DE1_course/tree/main/Term_Project_1/Original_layer_desc) as `.pdf` files – they are too large and complicated to detail directly in the report.  
Worth noting that the relationship scemas aren’t complete and the documentation is poorly made.

My operational layer (narrowed down version of the original database) is created of relevant data according to the analytical purposes - no item characteristics is needed except for price. The relevant parts of the original dataset were also modified due to privacy issues – these are real Customers with real postal addresses. Only the name and the ZIP codes were kept so I can identify cross-buyers (same Customer on different sales channel – name wouldn’t be unique enough). furthermore, the vendor occasionally sells other items than postcards, these items were also excluded.  

For the operational layer, the .sql files were downloaded from the phpMyAdmin interface. The codes were modified manually so they can be imported into our database.  

Additionally, EUR_USD exchange rates were downloaded from the [European Central Bank's website](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/usd.xml). Transformed into csv (+ values for missing dates filled and period shortened in R) since MySQL Workbench doesn’t support xml files. The csv used in the code is [here](https://github.com/bmbln/CEU_DE1_course/blob/335754ab55738b882c9d32d458803b2868e9a4d4/Term_Project_1/data_and_queries/EUR_USD%20exchange%20rate.csv).   

An auxiliary table was also created for constructing “real” order level based on shipping days.  

## Operational layer  
Operational layer was created using the [following query](https://github.com/bmbln/CEU_DE1_course/blob/335754ab55738b882c9d32d458803b2868e9a4d4/Term_Project_1/data_and_queries/Postcards_database.sql) `Postcards_database.sql`
- Kindly pay attention to change path in line 32 and `LINE ENDING` in line 35 for reading `.csv` file according to local environment. 
- Some warnings: Sales dates were downloaded as datetime but stored as date – SQL truncates the values and sends warning messages. Exchange rates are stored as dates, we can save extra steps in ETL and no loss of relevant information after this truncate.  

In the operational layer, sales data is split into different tables according to the sales channel logic. 

<p align="center">
  <img width="70%" src="https://github.com/bmbln/CEU_DE1_course/blob/e713939c1cef928733d6934db4cb754c315c38f6/Term_Project_1/pictures/operational_layer.png">
</p>

### eBay channels
The 3 of them (`de_`, `fr_`, `us_`) have the same logic, the following 3 tables were created: 
- address: `country`, `name` and `ZIP` of the Customer, `standard_name` of the Customer (see `Customer` table), `address_id`  
- orders: `sale date`, `total` amount paid (shipping fee incl.), `currency` (EUR/USD), `sales_id` and `address_id` (ref. to address tables). There is a different `ID` due to data problems
-	order content: `ebay_id` (identifier of single object), unique `ID` (`ebay_id` might be wrong and duplicated), `price` of the unique postcard and `quantity` purchased, `sale_id` (ref. to orders table)  

### HipPostcard
Slightly different content due to different information structur, ethe following 3 tables were created: 
- address: `country`, `buyer_firstname` and `buyer_lastname`, `ZIP` of the customer, `standard_name` (see `Customer` table) and `address_id`  
- orders: `sales_date`, `total` amount paid (without shipping fee), `postage` paid, `currency` (EUR/USD), `sales_id` and `address_id` (ref. to address table). There is a different `ID` due to data problems
- order content: `hip_id` (identifier of single object), unique `ID` (`hip_id` might be wrong and duplicated), `price` of the unique postcard and `quantity` purchased, `sale_id` (ref. to orders table)

### Delcampe
Only a single table, because we don’t have order level data:  
- `buyer_firstname` and `buyer_surname`, `country` and `ZIP` of Customers, `standard_name` (see `Customer` table), `price`, `currency` and `quantity` of the given postcard purchased, `sales_date`

### Auxiliary tables
Currency exchange rates:  
- `date` and EUR/USD `rates`  

Shipping days table:  
- `date`, `shipping_day`  
- using stored procedures, an empty table was populated with dates from 24/07/2019 (earliest sale date in the dataset) and today. `shipping_day` value constructed based on year, week and week of the day (basically postcards purchased between Monday and Thursday are `day_1`, between Friday and Sunday `day_2` per weeks and years). It is necessary for the analytical layer so we can use the Delcampe sales data, and the other sales channels are cleaned as well.  
 
Customer table: 
- `id`, `standard_name`, `name`, `ZIP`  
-	in order to identify cross-channel buyers, a standard customer key was constructed by concatenating name (or first and last name) and ZIP code in each relevant table. White spaces and special characters were removed so we won’t miss a match. Some cross-buyers still won’t be matched for various reasons (uses different shipping addresses for different orders or serious typo, etc.), but we still gained some matches.  
- the `standard_name`s, `name`s and `ZIP`s were selected from the different tables and appended. `SELECT DISTINCT` was used. 

## Analytics plan and Analytical layer

My analytics plan is the following:

- Loading in data [`Postcards_database.sql`](https://github.com/bmbln/CEU_DE1_course/blob/335754ab55738b882c9d32d458803b2868e9a4d4/Term_Project_1/data_and_queries/Postcards_database.sql) 
- Create ETL pipeline in stored procedure for the denormalised data warehouse [`ETL_postcards_dw.sql`](https://github.com/bmbln/CEU_DE1_course/blob/e713939c1cef928733d6934db4cb754c315c38f6/Term_Project_1/data_and_queries/ETL_postcards_dw.sql) 
- Create ETL pipeline in stored procedures for data marts [`ETL_data_marts.sql`](https://github.com/bmbln/CEU_DE1_course/blob/e713939c1cef928733d6934db4cb754c315c38f6/Term_Project_1/data_and_queries/ETL_data_marts.sql) 

The creation of the denormalized data warehouse is tricky because we need to **bring the different sales channels on similar structures** (different joins and logic needed), **recalculate some values** based on currencies, then **append the tables**. In the warehouse each row is an order on *real order level* (see explanation of *real order level* in *item and sale characteristics* section) between 03/11/2020 and 28/10/2021.

### eBay channels
Unlike in every decent programming language, stored procedures in SQL can’t take table names as parameters, therefore I couldn’t save time on eBay channels even though they share the same structures. 

The first step aggregated information on the original order level:  
- 3 tables joined (order, order content, shiping address)
- calculating shipping fees (+ taxes) and corrections. In the order tables, the total amount paid was indicated, the sum of prices from the order content tables was deducted. If positive, then taken as shipping fees (+ taxes are also included for some extra-EU countries), if negative then considered as corrections, because in some cases discounts are applied on the final invoice or some items were refunded because of physically missing from stock. Unfortunately, the original database doesn’t indicate in the order content table if the item was refunded, nor is the postage fee treated properly, therefore it brings a slight bias into the analysis – no postage fee for corrected invoices even though in reality, they had shipping fee. 
- quantity of postcards aggregated from order content table

The second step aggregated information on the *real order level*:
- grouped by customer (`standard_name`) and shipping day
-	values recalculated in EUR when necessary

### HipPostcard 
The steps were the same as for eBay, but the total in the original table is without shipping fee and we have distinct variable for shipping. The calculations were slightly different, accordingly. 

### Delcampe
We don’t have order level data, so we had to construct it in one step on *real order level* (based on shipping days):
- business as usual, for orders above 70 EUR 7 EUR is charged as shipping fee and 2 EUR below. It is an estimate, sometimes shipping is for free or 7 EUR even below 70 EUR if the Customer requested tracked shipment. 
-	corrections are 0, we have no information on it
- Everything is in EUR, so no need to recalculate values

### Cleaning
For each channel, I run some cleaning by excluding orders (on the original order level):
- that potentially contained lots from the 6th channel. The price of these items is always an integer, so they can be identified with MOD() functions. Some auctions that were sold on a whole number price might be lost, but it’s a less serious issue. The American eBay was excluded from this cleaning process, because it isn’t spoiled with 6th channel items and auctions are the main players.
-	where the `sum` of `base_total` and the correction is below 2 EUR (cheapest item in the whole shop is 2.99 EUR). Therefore the refunded or otherwise problematic orders are excluded. 

The 4 normalized tables were appended. Variable types were formatted to decimals as a final touch. 

## Data mart
3 data marts were created as views in stored procedures.  
It could have been great to use sales channels as parameters in the 2nd and 3rd marts and define TOP “how many” Customers we want to see, but MySQL doesn’t take parameters in views. Nor does the `LIMIT` clause accept parameters. 

### Large customers
The data mart identifies the TOP 20 largest (cross-channel) Customers and aggregates their purchases. Ordered by total purchases.  

It displays the Customer name and the country they reside in. Total order value, average order value, average price of purchased postcards, number of postcards ordered and their share in total turnover across sales-channels. For a better view, the values are formatted in EUR or %  

Yes, there were 3 Customers who spent over 3000 EUR on vintage postcards the last year accounting for 5% of the total turnover…

### Largest markets
The data mart aggregates purchases across sales channels by countries. There is no LIMIT clause in displaying TOP markets, it’s a general overview.  

It displays country name, total order value, number of postcards purchased, number of orders, average order value, average price of purchased postcards, largest and smallest order value. It also calculates shares in turnover, total number of purchased postcards and total order numbers. For a better view, the values are formatted in EUR or % here as well.  

Unsurprisingly, the largest markets correspond to the eBay sales channels. France is ahead of every other market accounting for a third of the total turnover. With Germany and the US, the TOP 3 market’s share is 2/3.  

### Order size
For the data mart, 3 order size categories were created based on how many postcards the given orders contain. The point is to see the prevalence of very small orders with 1 postcard only. The size categories: 1 card, 2-5 cards, 6-10 cards and over 11 cards.  

It displays order size category, total value of orders per category, number of orders, share in total turnover and number of orders, average order value, smallest and largest order values. For a better view, the values are formatted in EUR or % here as well.  

Very small orders with only one card are quite frequent, almost ¾ of the orders are this small but they only account for a third of the turnover. Large orders with over 11 cards only account for 3% of the number of orders but they bring a quarter of the total turnover. 
