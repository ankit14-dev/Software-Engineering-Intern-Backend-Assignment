-- Active: 1765792167237@@ep-young-mouse-a1oq2npn-pooler.ap-southeast-1.aws.neon.tech@5432@netflix

/* Set search_path to find tables in public schema */
SET search_path TO public;

/* show all tables */
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';


-- Get detailed schema information for each table
SELECT
    column_name
FROM information_schema.columns
WHERE
    table_schema = 'public'
ORDER BY table_name, ordinal_position;


-- Identify primary keys and foreign keys (relationships)
SELECT tc.table_name, kcu.column_name, tc.constraint_type
FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
WHERE
    tc.table_schema = 'public';


-- Check for NULL values in each column
SELECT
    COUNT(*) as total_rows,
    COUNT(*) - COUNT(cast_members) as null_count,
    ROUND(
        100.0 * (COUNT(*) - COUNT(cast_members)) / COUNT(*),
        2
    ) as null_percentage
FROM public.netflix_shows;

SELECT
    key AS column_name,
    COUNT(*) FILTER (
        WHERE
            value = 'null'
    ) AS null_count,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE
                value = 'null'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS null_percentage
FROM public.netflix_shows t, jsonb_each(to_jsonb(t))
GROUP BY
    key
ORDER BY null_percentage DESC;

SELECT *
FROM (
        SELECT *,
            -- Counts how many times this specific grouping appears
            COUNT(*) OVER (
                PARTITION BY
                    title
            ) as count
        FROM public.netflix_shows
    ) sub
WHERE
    sub.count > 1;

-- Find duplicate records (adjust columns as needed)
SELECT title, description, COUNT(*)
FROM public.netflix_shows
GROUP BY
    title,
    description
HAVING
    COUNT(*) > 1;

-- Check for inconsistent data (e.g., varying formats)SELECT
SELECT    
    'type' as column_checked,
    LOWER(type) as normalized_value,
    ARRAY_AGG(DISTINCT type) as variations_found,
    COUNT(*) as count
FROM public.netflix_shows
GROUP BY
    LOWER(type)
HAVING
    COUNT(DISTINCT type) > 1
UNION ALL
-- Repeat for other categorical columns like 'rating' or 'country'
SELECT 'duration', LOWER(rating), ARRAY_AGG(DISTINCT rating), COUNT(*)
FROM public.netflix_shows
GROUP BY
    LOWER(rating)
HAVING
    COUNT(DISTINCT rating) > 1;

SELECT show_id, duration
FROM public.netflix_shows
WHERE
    -- Checks if the length of the original text differs from the trimmed version
    LENGTH(title) <> LENGTH(TRIM(title))
    OR LENGTH(type) <> LENGTH(TRIM(type))
    OR LENGTH(rating) <> LENGTH(TRIM(rating));

SELECT rating, COUNT(*) as frequency
FROM public.netflix_shows
GROUP BY
    rating
ORDER BY frequency ASC;

-- Identify data quality issues
SELECT *
FROM public.netflix_shows
WHERE
    rating IS NULL
    OR TRIM(rating) = ''
    OR rating ~* '[^a-zA-Z0-9\s-]';
-- contains special characters


/* show all data from netflix_shows table */

select * from public.netflix_shows;