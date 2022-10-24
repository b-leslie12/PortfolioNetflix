
-- Get an initial view of the data that we will be working with


SELECT *
FROM netflix..netflixInfo


-- Check the data for duplicates
	-- Since show_id is our primary key in this table, we will check to ensure there are not multiple entries with the same show_id

SELECT show_id, COUNT(show_id) as num
FROM netflix..netflixInfo
GROUP BY show_id
ORDER BY num DESC

	-- There are no duplicates in our table


-- We will check each column for null values
SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE show_id IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE type IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE title IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE director IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE cast IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE country IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE date_added IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE release_year IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE rating IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE duration IS NULL

SELECT COUNT(*)
FROM netflix..netflixInfo
WHERE listed_in IS NULL

-- The following columns have nulls that we need to address
	-- director, 2634 nulls
	-- cast, 825 nulls
	-- country, 831 nulls
	-- date_added, 98 nulls
	-- rating, 4 nulls
	-- duration, 3 nulls


	-- Without more information, we cannot confidently replace the nulls in the director or cast columns with real values
	-- We will replace them with N/A for now

UPDATE netflix..netflixInfo
SET director = 'N/A'
WHERE director IS NULL

UPDATE netflix..netflixInfo
SET cast = 'N/A'
WHERE cast IS NULL

	-- In an effort to replace NULLs in the country column, we can assume that directors will likely only produce movies in one country
	-- We can use the director to fill in the missing values in the country column
	-- We will create a query to test this theory to ensure accuracy

-- Create a temp table that includes directors with >3 distinct country results

SELECT director, COUNT(DISTINCT country) as num
INTO #directorsCountries
FROM netflix..netflixInfo
GROUP BY director
HAVING COUNT(DISTINCT country) > 3

-- See how many directors have > 3 country results
SELECT COUNT(*) as num_of_multicountry_directors
FROM #directorsCountries

	-- There are only 13 directors who have > 3 country results

-- Looking at directors and countries from the temporary table

SELECT director, country
FROM netflix..netflixInfo
WHERE director IN
(
	SELECT director
	FROM #directorsCountries
) AND director != 'N/A'
ORDER BY director

-- From the above query, we can conclude that most directors, even those with > 3 country results, most often produce in only 1 country.
-- This country is often the first country listed in cells with >1 country.
-- For the purpose of this exercise, we will use the director column to replace NULLs in the country column

UPDATE netflix..netflixInfo
SET netflix..netflixInfo.country = n2.country
FROM netflix..netflixInfo
JOIN netflix..netflixInfo as n2 
	ON netflix..netflixInfo.director = n2.director
WHERE netflix..netflixInfo.country IS NULL

-- Now when we check for null values, our country column only returns 302 NULLs instead of 831.
-- We will replace the rest of the NULLs in the country column with 'N/A'

UPDATE netflix..netflixInfo
SET country = 'N/A'
WHERE country IS NULL

-- In order to properly visualize our geographical data, we must split the country column to only include the primary country of production. This, we will assume, is the first country listed.

UPDATE netflix..netflixInfo
SET country = TRIM(REVERSE(PARSENAME(REVERSE(REPLACE(country, ',', '.')), 1)))


-- Now we will begin preparing our data for visualization by querying and comparing columns we would like to analyze


	-- Comparing number of shows vs movies added by year
SELECT type, count(*) as count, LEFT(CAST(date_added AS date), 4) as year_added
FROM netflix..netflixInfo
WHERE date_added IS NOT NULL
GROUP BY LEFT(CAST(date_added AS date), 4), type
ORDER BY LEFT(CAST(date_added AS date), 4) ASC, type DESC

	-- Showing the directors with the most productions on Netflix
SELECT TOP 10 director, COUNT(*) as num_of_productions
FROM netflix..netflixInfo
WHERE director != 'N/A'
GROUP BY director
ORDER BY num_of_productions DESC

	-- Showing number of productions by genre
WITH cte as 
(
SELECT value listed_in
FROM netflix..netflixInfo
	CROSS APPLY STRING_SPLIT(listed_in, ',')
)

SELECT TRIM(listed_in) as genre, COUNT(*) AS num_in_genre
FROM cte
GROUP BY listed_in
ORDER BY num_in_genre DESC

	-- Showing productions by country

SELECT country, COUNT(*) as num_of_productions
FROM netflix..netflixInfo
WHERE country != 'N/A'
GROUP BY country
ORDER BY num_of_productions DESC

	-- Showing average release year of shows/movies added to Netflix by year

SELECT ROUND(AVG(release_year), 3) as avg_release_year, LEFT(CAST(date_added AS date), 4) as year_added
FROM netflix..netflixInfo
WHERE LEFT(CAST(date_added AS date), 4) IS NOT NULL and release_year IS NOT NULL
GROUP BY LEFT(CAST(date_added AS date), 4)
ORDER BY year_added DESC