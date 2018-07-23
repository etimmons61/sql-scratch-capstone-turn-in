SELECT COUNT(DISTINCT utm_source) AS 'Source Count'
FROM page_visits;

SELECT DISTINCT utm_source, COUNT(utm_campaign) AS 'Source Cnt'
FROM page_visits
GROUP BY utm_source
;
/* This query looks at first touch */
/*
WITH first_touch AS (
    SELECT user_id,
        MIN(timestamp) as first_touch_at
    FROM page_visits
    GROUP BY user_id)
SELECT ft.user_id,
    ft.first_touch_at,
    pv.utm_source,
		pv.utm_campaign
FROM first_touch ft
JOIN page_visits pv
    ON ft.user_id = pv.user_id
    AND ft.first_touch_at = pv.timestamp
ORDER BY pv.utm_source
;
*/

SELECT COUNT(DISTINCT utm_campaign) AS 'Campaign Count'
FROM page_visits;

SELECT utm_campaign,  COUNT (utm_source) AS 'Campaign Cnt'
FROM page_visits pv
GROUP BY utm_campaign
ORDER BY COUNT(utm_source) DESC;


WITH sources AS(
  SELECT utm_source, utm_campaign,
  CASE
    WHEN utm_source LIKE 'buzzfeed' 
    THEN 1  ELSE 0  END as 'buzz',
  CASE
    WHEN utm_source LIKE 'email'
    THEN 1  ELSE 0  END as 'email',
  CASE
    WHEN utm_source LIKE 'facebook'
    THEN 1  ELSE 0  END as 'fb',
  CASE
    WHEN utm_source LIKE 'google'
    THEN 1  ELSE 0  END as 'google',
  CASE
    WHEN utm_source LIKE 'medium'
    THEN 1  ELSE 0  END as 'med',
  CASE
    WHEN utm_source LIKE 'nytimes'
    THEN 1  ELSE 0  END as 'nyt'
  FROM page_visits)
SELECT utm_campaign,  SUM (buzz), SUM(email), SUM(fb), SUM(google),
     SUM(med), SUM(nyt)
FROM sources
GROUP BY utm_campaign;

/* Queryto check data for a specific campaign */
/*
SELECT utm_campaign, utm_source
FROM page_visits
WHERE utm_campaign LIKE 'cool-tshirts%'
ORDER BY utm_source;
*/

/* Distinct page names */
SELECT page_name, COUNT (page_name)
FROM page_visits
GROUP BY page_name
ORDER BY page_name;


/* First Touch by campaign */
WITH first_touch AS (
    SELECT user_id,
        MIN(timestamp) as first_touch_at
    FROM page_visits
    GROUP BY user_id)
SELECT pv.utm_campaign, COUNT(pv.utm_source) AS 'First Touch Count'
FROM first_touch ft
JOIN page_visits pv
    ON (ft.user_id = pv.user_id
       AND ft.first_touch_at = pv.timestamp)
GROUP BY pv.utm_campaign
ORDER BY COUNT(pv.utm_source) DESC;

/* Last Touch by campaign */
WITH last_touch AS (
    SELECT user_id, MAX(timestamp) as last_touch_at
    FROM page_visits
    GROUP BY user_id)
SELECT pv.utm_campaign, COUNT(pv.utm_source) AS 'Last Touch Count'
FROM last_touch lt
JOIN page_visits pv
     ON (lt.user_id = pv.user_id
         AND lt.last_touch_at = pv.timestamp)
GROUP BY pv.utm_campaign
ORDER BY COUNT(pv.utm_source) DESC;

SELECT COUNT(DISTINCT user_id) AS 'Unique Purchasers'
FROM page_visits
WHERE page_name LIKE '4 - purchase';

/* Last Touch with Purchase by campaign */
WITH last_touch AS (
    SELECT user_id, MAX(timestamp) as last_touch_at
    FROM page_visits
    GROUP BY user_id)
SELECT pv.utm_campaign, COUNT(pv.utm_source) AS 'Purchase Count'
FROM last_touch lt
JOIN page_visits pv
    ON (lt.user_id = pv.user_id
        AND lt.last_touch_at = pv.timestamp)
WHERE pv.page_name LIKE '4 - purchase'
GROUP BY pv.utm_campaign
ORDER BY COUNT(pv.utm_source) DESC;

/* Purchasers First Touch Attribution */
/* Add percentage */
WITH purch_cam AS (
  WITH purchasers AS (
     SELECT user_id
     FROM page_visits
     WHERE page_name LIKE '4 - purchase'), 
  total_purchases AS (
     SELECT COUNT(DISTINCT user_id) AS 'Unique Purchasers'
     FROM purchasers
     ) 
SELECT p.user_id, pv.utm_campaign, pv.utm_source, 
    min(pv.timestamp), pv.page_name,
    total_purchases.'Unique Purchasers' AS Total
FROM purchasers p
JOIN page_visits pv
    ON p.user_id = pv.user_id
CROSS JOIN total_purchases
GROUP BY p.user_id
ORDER BY p.user_id ASC, pv.timestamp DESC
)
SELECT pc.utm_campaign, COUNT(pc.user_id) as "First Touch", 
ROUND(100.0*COUNT(pc.user_id)/pc.Total,2) AS 'Percent'
FROM purch_cam pc
GROUP BY pc.utm_campaign
ORDER BY COUNT(pc.user_id) DESC;

/* Purchasers last touch by campaign */
WITH purch_campaign AS (
   WITH purchasers AS (
       SELECT user_id
       FROM page_visits
       WHERE page_name LIKE '4 - purchase'),
     total_purchases AS (
       SELECT COUNT(DISTINCT user_id) AS 'Unique Purchasers'
       FROM purchasers)
     SELECT p.user_id, pv.utm_campaign, pv.utm_source, 
        max(pv.timestamp), pv.page_name,
        total_purchases.'Unique Purchasers' AS Total
     FROM purchasers p
     JOIN page_visits pv
         ON p.user_id = pv.user_id
     CROSS JOIN total_purchases
     GROUP BY p.user_id
     ORDER BY p.user_id ASC, pv.timestamp DESC
)
SELECT pc.utm_campaign, COUNT(pc.user_id) as "Last Touch", ROUND(100.0*COUNT(pc.user_id)/pc.Total,2) AS 'Percent'
FROM purch_campaign pc
GROUP BY pc.utm_campaign
ORDER BY COUNT(pc.user_id) DESC;


SELECT COUNT(DISTINCT user_id)
FROM page_visits;

/* Purchasers last touch = retargetting source campaign (i.e. First Touch) */
WITH purchasers AS (
     SELECT user_id
     FROM page_visits
     WHERE page_name LIKE '4 - purchase'
     ),
  last_touch AS (
     SELECT p.user_id, pv.utm_campaign, pv.utm_source, 
            max(pv.timestamp)
     FROM purchasers p
     JOIN page_visits pv
         ON (p.user_id = pv.user_id
             AND (pv.utm_campaign LIKE 'weekly%' OR pv.utm_campaign                     LIKE 'retargetting%' 
                  OR pv.utm_campaign LIKE 'paid%'))
     GROUP BY p.user_id
  ),
  first_touch AS (
     SELECT p.user_id, pv.utm_campaign, pv.utm_source, 
           min(pv.timestamp)
     FROM purchasers p
     JOIN page_visits pv
         ON p.user_id = pv.user_id
     JOIN last_touch lt
         ON p.user_id = lt.user_id
     GROUP BY p.user_id
  )
SELECT ft.utm_campaign AS 'FT Campaign', COUNT(ft.user_id) AS 'Retargetted Purchasers'
FROM first_touch ft
GROUP BY ft.utm_campaign;