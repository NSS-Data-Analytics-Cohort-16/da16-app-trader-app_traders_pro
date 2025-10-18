-- ### App Trader
-- Your team has been hired by a new company called App Trader to help them explore and gain insights from apps that are 
-- made available through the Apple App Store and Android Play Store. App Trader is a broker that purchases the rights to 
-- apps from developers in order to market the apps and offer in-app purchase. 

-- Unfortunately, the data for Apple App Store apps and Android Play Store Apps is located in separate tables with no 
-- referential integrity.

-- #### 1. Loading the data
-- a. Launch PgAdmin and create a new database called app_trader.  
-- b. Right-click on the app_trader database and choose `Restore...`  
-- c. Use the default values under the `Restore Options` tab. 
-- d. In the `Filename` section, browse to the backup file `app_store_backup.backup` in the data folder of this repository.  
-- e. Click `Restore` to load the database.  
-- f. Verify that you have two tables:  
--     - `app_store_apps` with 7197 rows  
--     - `play_store_apps` with 10840 rows

-- #### 2. Assumptions

-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, 
-- the purchase price is $10,000.

-- - For example, an app that costs $2.00 will be purchased for $20,000.
    
-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will 
--	 cost the same as a $1.00 app on both stores. 
    
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price 
-- 	 between the two stores. 

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, 
--	  regardless of the price of the app.
    
-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- - An app that is on both app stores will make $10,000 per month. 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. 
--	  If App Trader owns rights to the app in both stores, it can market the app for both stores for a single 
--    cost of $1000 per month.
    
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, 
--   regardless of the number of stores it is in.

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. 
--    In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 
--    can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
SELECT 
	name,
	rating,
	price,
	ROUND((rating / 0.5) + 1, 2)  AS longevity
FROM play_store_apps
WHERE rating IS NOT NULL
ORDER BY longevity DESC
--------------------
SELECT 
	name,
	rating,
	ROUND((rating / 0.5) +1, 2) AS longevity
FROM app_store_apps
WHERE rating IS NOT NULL
ORDER BY longevity DESC

-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding 
--   to the nearest 0.5.

--RATINGS, LONGEVITY, AVG RATINGS--NEED AVG LONGEVITY
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




-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since 
--    they can market both for the same $1000 per month.
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
----------------------
SELECT
	a.name,
	  CASE
        WHEN a.rating >= p.rating THEN a.rating
        ELSE p.rating
    END AS rating,
	case when a.rating is not null and p.rating is not null 
	     then 10000
		 when a.rating is not null and p.rating is not null
		 then 5000  else 0  
		 end *12   as monthly_earning,
		        1000 as marketing_cost,
			
	ROUND((a.rating + p.rating /2) /0.5,0) *0.5 as avg_rating,
	(ROUND(((a.rating + p.rating)/2) /0.5, 0)*0.5*2) + 1 as lifespan,
	(1000 * 12 * ((ROUND(((p.rating + a.rating) / 2) / 0.5, 0) * 0.5 * 2) + 1)) AS lifespan_year
	FROM app_store_apps as a
	left join play_store_apps as p
	on a.name = p.name

---------------------------------
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

-------------------------------------

with appstore as (
    select
        ap.name,
        p.rating as p_rating,
        a.rating as a_rating,
        cast(replace(p.price, '$', '') as numeric) as p_price,
        a.price as a_price,
        p.content_rating,
        a.primary_genre,
        p.genres as secondary_genre
    from (
        select name
        from app_store_apps
        intersect
        select name
        from play_store_apps ) AS ap
    LEFT JOIN play_store_apps AS p ON p.name = ap.name
    LEFT JOIN app_store_apps AS a ON a.name = ap.name)
	
select
    name,
    ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 AS avg_rating,
    (ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 * 2) + 1 AS lifespan,
    greatest(p_price, a_price) AS max_price,
    case
        when greatest(p_price, a_price) <= 1 then 10000
        else greatest(p_price, a_price) * 10000
    end as purchase_price,
    case
        when p_rating is not null and a_rating is not null then 10000
        when p_rating is not null or a_rating is not null then 5000
        else 0
    end as monthly_earning,
    1000 AS marketing_cost,
    (
        ((ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 * 2) + 1) *
        case
            when p_rating is not null and a_rating is not null then 10000
            when p_rating is not null or a_rating is not null then 5000
            ELSE 0
        END * 12
    ) -
    case
        when greatest(p_price, a_price) <= 1 then 10000
        else greatest(p_price, a_price) * 10000
    end -
    (1000 * 12 * ((ROUND(((p_rating + a_rating) / 2) / 0.5, 0) * 0.5 * 2) + 1)) AS lifespan_profit,
    content_rating,
    primary_genre,
    secondary_genre,
    'both' AS store
from appstore
group by name, p_rating, a_rating, p_price, a_price, content_rating, primary_genre, secondary_genre
having ROUND((p_rating + a_rating) / 2, 1) >= 3.0
order by lifespan_profit DESC
--limit 25;

-- #### 3. Deliverables

-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps 
--    that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export 
--    query results to create charts in Excel for your report. 