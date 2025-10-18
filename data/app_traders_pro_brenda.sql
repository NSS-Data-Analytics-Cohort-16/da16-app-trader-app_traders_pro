Assumptions

Based on research completed prior to launching App Trader as a company, you can assume the following:

a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
- For example, an app that costs $2.00 will be purchased for $20,000.
    
- The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
- If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 
SELECT 
	app_store.name, 
	play_store.rating,
	app_store.price AS app_price,
	play_store.price AS play_price,
	AVG(app_store.price + play_store.price) * 10000 AS purchase_price
FROM app_store_apps AS app_store
LEFT JOIN play_store_apps AS play_store
USING(name)
GROUP BY app_store.name, play_store.rating
ORDER BY rating DESC

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


b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
- An app that costs $200,000 will make the same per month as an app that costs $1.00. 

- An app that is on both app stores will make $10,000 per month. 

SELECT *
FROM app_store_apps
LEFT JOIN play_store_apps
USING(name)
WHERE app_store_apps.rating >= 3
	AND play_store_apps.rating >= 3
GROUP BY app_store_apps.name, play_store_apps.rating, app_store_apps.size_bytes
ORDER BY app_store_apps.review_count DESC
LIMIT 100 

SELECT *
FROM app_store_apps
ORDER BY review_count DESC
LIMIT 100 

c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
- An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

SELECT
	p.name,
	a.name,
	p.rating,
	a.rating,
	ROUND(AVG(p.rating + a.rating), 1) AS avg_rating
FROM play_store_apps a
FULL OUTER JOIN app_store_apps p
USING (name)
GROUP BY p.name, a.name, p.rating, a.rating;


d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
- App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

--This is NOT what I want to use
SELECT app_store_apps.name, play_store_apps.rating
FROM app_store_apps
LEFT JOIN play_store_apps
USING(name)
GROUP BY app_store_apps.name, play_store_apps.rating
ORDER BY name DESC
LIMIT 100 

--YES USE THIS ONE, returns 329 rows
SELECT
	p.name,
	a.name,
	p.rating,
	a.rating,
	ROUND((p.rating + a.rating) /2, 2) AS avg_rating
FROM play_store_apps a
FULL OUTER JOIN app_store_apps p
USING (name)
WHERE p.rating IS NOT NULL
	AND a.rating IS NOT NULL
GROUP BY p.name, a.name, p.rating, a.rating
ORDER BY avg_rating DESC;


e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.

SELECT name
FROM app_store_apps
UNION
SELECT name
FROM play_store_apps
ORDER BY name

(SELECT app_store_apps.name
FROM app_store_apps
LEFT JOIN play_store_apps
ON app_store_apps.name = play_store_apps.name)
INTERSECT
(SELECT play_store_apps.name
FROM app_store_apps
LEFT JOIN play_store_apps
ON app_store_apps.name = play_store_apps.name)
ORDER BY name ASC

#### 3. Deliverables

a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

b. Develop a Top 10 List of the apps that App Trader should buy.

c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report. 

with appstore as(
     select ap name,
	        a.rating as a_rating,
			p.rating as p_rating,
			cast(replace(p.price, '$', '') as numeric) as p_price,
			a.price as a_price,
			p.content_rating
	  from (
	      select name
          from app_store_apps
          intersect
          select name
          from play_store_apps
          ) as ap
left join app_store_apps as a
on a.name = ap.name
left join play_store_apps as p
on p.name = ap.name)
select *
from appstore;

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



SELECT
	name,
	ROUND(ROUND(AVG(psa.rating) * 2) / 2,2) AS rounded_rating,
CASE
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 0.0 THEN 1
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 0.5 THEN 2
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 1.0 THEN 3
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 1.5 THEN 4
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 2.0 THEN 5
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 2.5 THEN 6
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 3.0 THEN 7
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 3.5 THEN 8
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 4.0 THEN 9
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 4.5 THEN 10
	WHEN ROUND(AVG(psa.rating) * 2) / 2 = 5.0 THEN 11

(SELECT
	name,
	REPLACE(price, '$', '')::numeric AS price,
	'playstore' AS store,
	CASE WHEN
		REPLACE(price, '$', '')::numeric <= 1.00::numeric then 10000.0
		WHEN
		REPLACE(price, '$', '')::numeric <= 1.00::numeric then REPLACE(price, '$', '')::numeric * 10000.0
		ELSE '0'
	END AS purchase_price
FROM play_store_apps)
UNION
(SELECT
	name,
	price,
	'appstore' AS store,
	CASE
		WHEN price <= 1.00 then 10000.0
		WHEN price > 1.00 then price * 10000.0
		ELSE '0'
		END AS purchase_price,
		CASE WHEN
		name IN (
			SELECT
				name
			FROM app_store_apps)
			INTERSECT
			(SELECT
			name
		FROM play_store_apps
		) then 2
		ELSE 1
		END AS store_count,
		1000 AS per_month
FROM app_store_apps
)
ORDER BY price DESC, purchase_price DESC
			
SELECT
	a.name,
	
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
GROUP BY a.name, a.rating, p.rating 

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
limit 10;
