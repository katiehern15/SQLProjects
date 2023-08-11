/* What is the rate of crime for each neighborhood in Denver? */
USE denvercrime;
SELECT
	COUNT(c.incident_id) AS num_incidents,
    c.neighborhood_id,
    n.population,
    (COUNT(c.incident_id)/sum(n.population)) * 1000 AS crime_rate
FROM crime22 c
	JOIN
	neighborhoods n ON n.neighborhood_id = c.neighborhood_id
GROUP BY c.neighborhood_id, n.population
ORDER BY crime_rate;

/* Create a view representing table generated in the previous query */
CREATE OR REPLACE VIEW v_crimerate AS
SELECT
	COUNT(c.incident_id) AS num_incidents,
    c.neighborhood_id,
    n.population,
    (COUNT(c.incident_id)/sum(n.population)) * 1000 AS crime_rate
FROM crime22 c
	JOIN
	neighborhoods n ON n.neighborhood_id = c.neighborhood_id
GROUP BY c.neighborhood_id, n.population
ORDER BY crime_rate;

/* Create a ranking of each neighborhood, with "1" being the neighborhood with the highest crime rate */
SELECT n.neighborhood_id, sum(cr.num_incidents) AS num_incidents,
               ROW_NUMBER() OVER (ORDER BY sum(cr.num_incidents) DESC) AS neighborhood_rank
        FROM v_crimerate cr
        JOIN neighborhoods n ON n.neighborhood_id = cr.neighborhood_ID
        GROUP BY neighborhood_ID;
      
/* What are the 3 most highly reported crimes in the top 5 neighborhoods for crime? */
SELECT
	neighborhood_id,
    offense_type_id,
    total_incidents
FROM (
	SELECT cr.neighborhood_id,
			c.offense_type_id,
            COUNT(c.incident_id) AS total_incidents,
            ROW_NUMBER() OVER (PARTITION BY cr.neighborhood_id ORDER BY COUNT(c.incident_id) DESC) AS crime_rank
	FROM crime22 c 
    JOIN v_crimerate cr ON cr.neighborhood_id = c.neighborhood_id
    GROUP BY cr.neighborhood_id, c.offense_type_id
    ) ranked_crimes
WHERE crime_rank <= 3

AND neighborhood_id IN (
	SELECT neighborhood_id
    FROM (SELECT
    neighborhood_id,
    crime_rate,
    RANK() OVER (ORDER BY crime_rate DESC) AS neighborhood_rank
FROM
    v_crimerate
ORDER BY
    neighborhood_rank) top_neighborhoods
    WHERE neighborhood_rank <= 5
)
GROUP BY offense_type_id, neighborhood_id
ORDER BY neighborhood_id, total_incidents DESC;

/* Here I saved the second select statement from the above query as a view for later use */
CREATE OR REPLACE VIEW v_top_neighborhoods AS
SELECT
    neighborhood_id,
    crime_rate,
    RANK() OVER (ORDER BY crime_rate DESC) AS neighborhood_rank
FROM
    v_crimerate
ORDER BY
    neighborhood_rank;
    
/* What are the safest neighborhoods in Denver? */
SELECT
	neighborhood_rank,
    neighborhood_id,
    crime_rate
FROM v_top_neighborhoods
ORDER BY crime_rate
LIMIT 10;

/*What is the month with the highest number of reported crimes? */
SELECT
	month(reported_date) AS report_month,
    offense_type_id,
    count(incident_id) AS monthly_offense_type
FROM crime22
GROUP BY offense_type_id, report_month
ORDER BY report_month, monthly_offense_type;
   
/* Categorize offense_type_id's into generalized crime types, and group by the number of incidents */
SELECT
    offense_type_id,
    COUNT(incident_id) AS num_incidents,
    CASE
        WHEN offense_type_id LIKE '%weapon%' THEN 'Gun-related Crime'
        WHEN offense_type_id LIKE '%sex%' THEN 'Sexual Crime'
        WHEN offense_type_id LIKE '%drug%' THEN 'Drug-Related Crime'
        WHEN offense_type_id LIKE '%theft%' OR offense_type_id LIKE '%property%' OR offense_type_id LIKE '%burglary%' OR offense_type_id LIKE '%robbery%' THEN 'Personal Property'
        WHEN offense_type_id LIKE '%disorder%' OR offense_type_id LIKE '%disturb%' THEN 'Public Conduct'
        WHEN offense_type_id LIKE '%homicide%' OR offense_type_id LIKE '%assault%' OR offense_type_id LIKE '%aslt%' THEN 'Violent Crime'
    END AS crime_type
FROM
    crime22
WHERE
    offense_type_id REGEXP 'weapon|sex|drug|theft|property|burglary|robbery|disorder|disturb|homicide|assault'
GROUP BY
    offense_type_id;

/* Save this table as a view for later use */
CREATE OR REPLACE VIEW v_offense_categories AS
SELECT
    offense_type_id,
    COUNT(incident_id) AS num_incidents,
    CASE
        WHEN offense_type_id LIKE '%weapon%' THEN 'Gun-related Crime'
        WHEN offense_type_id LIKE '%sex%' THEN 'Sexual Crime'
        WHEN offense_type_id LIKE '%drug%' THEN 'Drug-Related Crime'
        WHEN offense_type_id LIKE '%theft%' OR offense_type_id LIKE '%property%' OR offense_type_id LIKE '%burglary%' OR offense_type_id LIKE '%robbery%' THEN 'Personal Property'
        WHEN offense_type_id LIKE '%disorder%' OR offense_type_id LIKE '%disturb%' THEN 'Public Conduct'
        WHEN offense_type_id LIKE '%homicide%' OR offense_type_id LIKE '%assault%' OR offense_type_id LIKE '%aslt%' THEN 'Violent Crime'
    END AS crime_type
FROM
    crime22
WHERE
    offense_type_id REGEXP 'weapon|sex|drug|theft|property|burglary|robbery|disorder|disturb|homicide|assault'
GROUP BY
    offense_type_id;


