-- HW3 - Endes-Nagy Peter
-- Assuming that you have the birdstrikes database available
USE birdstrikes;

-- Exercise1
SELECT aircraft, airline, cost, SPEED,
	IF (SPEED < 100 OR SPEED IS NULL, "LOW_SPEED", "HIGH_SPEED") AS speed_category
	FROM  birdstrikes
	ORDER BY speed_category;
-- the solution is a table

-- Exercise2 How many distinct ‘aircraft’ we have in the database?
SELECT COUNT(DISTINCT aircraft) FROM birdstrikes;
-- 3

-- Exercise3 What was the lowest speed of aircrafts starting with ‘H’
SELECT MIN(speed) FROM birdstrikes 
WHERE aircraft LIKE 'h%' AND speed IS NOT NULL;
-- 9

-- Exercise4 Which phase_of_flight has the least of incidents?
SELECT phase_of_flight, COUNT(id) as no_incidents FROM birdstrikes
GROUP BY phase_of_flight
ORDER BY no_incidents
LIMIT 1;
-- Taxi

-- Exercise5 What is the rounded highest average cost by phase_of_flight?
SELECT phase_of_flight, ROUND(AVG(cost)) AS avg_cost FROM birdstrikes
WHERE cost IS NOT NULL
GROUP BY phase_of_flight
ORDER BY avg_cost DESC
LIMIT 1;
-- 54673

-- Exercise6 What the highest AVG speed of the states with names less than 5 characters?

-- Iowa


