-- #### 2. Assumptions
SELECT *
FROM play_store_apps
ORDER BY name

SELECT *
FROM app_store_apps
ORDER BY name



-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
-- - For example, an app that costs $2.00 will be purchased for $20,000.
    
-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- - An app that is on both app stores will make $10,000 per month. 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.


-- #### 3. Deliverables

-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report. 






SELECT a.name, a.rating, p.price
FROM app_store_apps a
INNER JOIN
	play_store_apps p ON a.name = p.name
ORDER BY a.rating DESC
	
-- Apps that are on both stores	

SELECT
    name,
    CASE
        WHEN app_rating >= play_rating THEN app_rating
        ELSE play_rating
    END AS rating,
    CASE
        WHEN 
            (CASE
                WHEN app_rating >= play_rating THEN app_rating
                ELSE play_rating
             END) = 0 THEN 1
        WHEN 
            (CASE
                WHEN app_rating >= play_rating THEN app_rating
                ELSE play_rating
             END) = 1 THEN 3
        ELSE FLOOR(
            (CASE
                WHEN app_rating >= play_rating THEN app_rating
                ELSE play_rating
             END) * 2
        )
    END AS lifespan_years
FROM (
    SELECT 
        a.name,
        a.rating AS app_rating,
        p.rating AS play_rating
    FROM app_store_apps a
    INNER JOIN play_store_apps p ON a.name = p.name
) AS joined_apps;


---Dennis' query---

WITH cross_platform AS (
	SELECT
		p.name AS play_store,
		a.name AS app_store,
		p.rating AS play_rating,
		ROUND((p.rating / 0.5) +1, 2) AS play_longevity,
		a.rating AS app_rating,
		ROUND((a.rating / 0.5) +1, 2) AS app_longevity,
		ROUND(AVG(p.rating + a.rating)/ 2, 1) AS avg_rating,
		ROUND((( (p.rating + a.rating)/ 2)/ 0.5) +1,2) AS avg_longevity
	FROM play_store_apps p
	FULL OUTER JOIN app_store_apps a
	USING (name)
	WHERE p.rating IS NOT NULL
		AND a.rating IS NOT NULL
	GROUP BY p.name, a.name, p.rating, a.rating
)
SELECT
	play_store,
	play_rating,
	app_store,
	app_rating,
	avg_rating,
	ROUND (AVG(avg_longevity), 2) AS overall_avg_longevity
FROM cross_platform
GROUP BY play_store, play_rating, app_store, app_rating, avg_rating
ORDER BY overall_avg_longevity DESC;

--- apple store purchase price---
SELECT
	name, 
	price, 
	CASE WHEN
	price::numeric <= 1.00::numeric then 10000.0
	WHEN
	price::numeric > 1.00::numeric then price::numeric * 10000
	ELSE '0'
	END AS pur_price
	FROM app_store_apps
	
	---play store purchase price---
	SELECT
		name,
		price,
		CASE WHEN
			REPLACE(price,'$','')::numeric <= 1.00::numeric then 10000.0
			WHEN
			REPLACE(price,'$','')::numeric <= 1.00::numeric then REPLACE(price, '$','')::numeric *10000.0
			ELSE '0'
			END AS pur_price
			FROM play_store_apps
---combine tables---


SELECT
    name,
    REPLACE(price, '$', '')::numeric AS price,
    'playstore' AS store,
    CASE 
        WHEN REPLACE(price, '$', '')::numeric <= 1.00 THEN 10000.0
        ELSE REPLACE(price, '$', '')::numeric * 10000.0
    END AS purchase_price,
    CASE 
        WHEN name IN (
            SELECT name FROM app_store_apps
            INTERSECT
            SELECT name FROM play_store_apps
        ) THEN 2
        ELSE 1
    END AS store_count,
    1000 AS per_month

FROM play_store_apps

UNION

SELECT
    name,
    price,
    'appstore' AS store,
    CASE
        WHEN price <= 1.00 THEN 10000.0
        ELSE price * 10000.0
    END AS purchase_price,
    CASE 
        WHEN name IN (
            SELECT name FROM app_store_apps
            INTERSECT
            SELECT name FROM play_store_apps
        ) THEN 2
        ELSE 1
    END AS store_count,
    1000 AS per_month

FROM app_store_apps

ORDER BY price DESC, purchase_price DESC

----life span of app and total revenue---

WITH shared_apps AS (
    SELECT name FROM app_store_apps
    INTERSECT
    SELECT name FROM play_store_apps
),

shared_details AS (
    SELECT
        ap.name,
        p.rating AS p_rating,
        a.rating AS a_rating,
        CAST(REPLACE(p.price, '$', '') AS numeric) AS p_price,
        a.price AS a_price,
        p.content_rating,
        a.primary_genre,
        p.genres AS secondary_genre
    FROM shared_apps ap
    LEFT JOIN play_store_apps p ON p.name = ap.name
    LEFT JOIN app_store_apps a ON a.name = ap.name
),

both_store_data AS (
    SELECT
        name,
        'both' AS store,
        GREATEST(p_price, a_price) AS price,
        ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 AS avg_rating,
        (ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 * 2) + 1 AS lifespan,
        CASE
            WHEN GREATEST(p_price, a_price) <= 1 THEN 10000
            ELSE GREATEST(p_price, a_price) * 10000
        END::numeric AS purchase_price,
        1000::numeric AS marketing_cost,
        ((ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 * 2) + 1) * 12000 AS total_marketing_cost,
        CASE
            WHEN GREATEST(p_price, a_price) <= 1 THEN 10000
            ELSE GREATEST(p_price, a_price) * 10000
        END + ((ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 * 2) + 1) * 12000 AS total_app_cost,
        (
            ((ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 * 2) + 1) *
            CASE
                WHEN p_rating IS NOT NULL AND a_rating IS NOT NULL THEN 10000
                WHEN p_rating IS NOT NULL OR a_rating IS NOT NULL THEN 5000
                ELSE 0
            END * 12
        ) - (
            CASE
                WHEN GREATEST(p_price, a_price) <= 1 THEN 10000
                ELSE GREATEST(p_price, a_price) * 10000
            END + ((ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 * 2) + 1) * 1000 * 12
        ) AS lifespan_profit,
        content_rating,
        primary_genre,
        secondary_genre
    FROM shared_details
    WHERE ROUND((p_rating + a_rating) / 2, 1) >= 3.0
),

single_store_data AS (
    (
        SELECT
            name,
            'playstore' AS store,
            REPLACE(price, '$', '')::numeric AS price,
            NULL::numeric AS avg_rating,
            NULL::numeric AS lifespan,
            CASE 
                WHEN REPLACE(price, '$', '')::numeric <= 1.00 THEN 10000.0
                ELSE REPLACE(price, '$', '')::numeric * 10000.0
            END::numeric AS purchase_price,
            1000::numeric AS marketing_cost,
            NULL::numeric AS total_marketing_cost,
            NULL::numeric AS total_app_cost,
            NULL::numeric AS lifespan_profit,
            NULL::text AS content_rating,
            NULL::text AS primary_genre,
            NULL::text AS secondary_genre
        FROM play_store_apps
        WHERE name NOT IN (SELECT name FROM shared_apps)
    )

    UNION ALL

    (
        SELECT
            name,
            'appstore' AS store,
            price::numeric AS price,
            NULL::numeric AS avg_rating,
            NULL::numeric AS lifespan,
            CASE
                WHEN price <= 1.00 THEN 10000.0
                ELSE price * 10000.0
            END::numeric AS purchase_price,
            1000::numeric AS marketing_cost,
            NULL::numeric AS total_marketing_cost,
            NULL::numeric AS total_app_cost,
            NULL::numeric AS lifespan_profit,
            NULL::text AS content_rating,
            NULL::text AS primary_genre,
            NULL::text AS secondary_genre
        FROM app_store_apps
        WHERE name NOT IN (SELECT name FROM shared_apps)
    )
)

-- Final combined output
SELECT *
FROM both_store_data

UNION ALL

SELECT *
FROM single_store_data

ORDER BY lifespan_profit DESC






