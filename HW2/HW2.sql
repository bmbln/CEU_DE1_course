-- assuming that the birdstikes table exists
USE birdstrikes;

-- Exercise1
CREATE TABLE employee
(id INTEGER NOT NULL,
emplyee_name VARCHAR(255) NOT NULL,
PRIMARY KEY(id));

-- Exercise2
SELECT state FROM birdstrikes 
LIMIT 144,1;
-- Tennesse

-- Exercise3
SELECT flight_date FROM birdstrikes 
ORDER BY flight_date DESC 
LIMIT 1;
-- 2000-04-18

-- Exercise4
SELECT DISTINCT cost FROM birdstrikes 
ORDER BY cost DESC 
LIMIT 49,1;
-- 5345
-- PS: it doesn't make much sense using DSTINCT on continuous decimal/integer variables

-- Exercise5
SELECT state FROM birdstrikes 
WHERE 
	state IS NOT NULL AND state != '' AND
    bird_size IS NOT NULL AND bird_size != '' 
LIMIT 1,1;
-- Colorado

-- Exercise6
SELECT datediff(now(), flight_date) AS Days_elapsed
FROM birdstrikes
WHERE
	WEEKOFYEAR(flight_date) = 52 AND
    state = 'Colorado';
-- 7940
-- p.s.: oddly enough the first 2 days of 2000's January are considered 52th Week (of 1999, I assume)