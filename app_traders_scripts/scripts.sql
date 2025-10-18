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

-- my note: I need name from apps on both table, rating, price range, content_rating, genrs 

select *
from app_store_apps

select *
from play_store_apps


select name 
from app_store_apps
intersect
select name
from play_store_apps 



with appstore as(
     select ap.name,
	        a.rating as a_rating,
			p.rating as p_rating,
			cast(replace(p.price, '$', '') as numeric) as p_price,
			a.price as a_price,
			p.content_rating,
			a.primary_genre, 
			p.genres 
	  from (
	      select a.name 
          from app_store_apps as a
          union
          select p.name
          from play_store_apps as p
          ) as ap
left join app_store_apps as a
on a.name = ap.name
left join play_store_apps as p
on p.name = ap.name)
select 
appstore.*,
greatest(a_price, p_price)  as high_price,
    case when greatest(a_price, p_price) <= 1 then 10000
	     else greatest(a_price, p_price)* 10000
		 end as purchase_price		 
from appstore;
------------
SELECT
	a.name,
	case when a.rating is not null and a.rating is not null 
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
	where ROUND((p.rating + a.rating) / 2, 1) >= 3.0

---------------
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

-----------------------------

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
        union
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
    
   
	
