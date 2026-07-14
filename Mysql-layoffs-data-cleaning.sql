-- ============================================================
-- Layoffs Dataset — Data Cleaning Project (MySQL)
-- Pipeline: Raw -> Deduplicated -> Nulls/Blanks Handled -> Standardized
-- ============================================================
-- STEP 1: DEDUPLICATION
-- ============================================================

-- Create a working copy of the raw table so the original stays untouched
CREATE TABLE layoffs_2
LIKE layoffs;

INSERT INTO layoffs_2
SELECT * FROM layoffs;

-- Preview duplicates using ROW_NUMBER() over all columns that define a unique record
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY company, location, industry, total_laid_off,
                         percentage_laid_off, `date`, stage, country, funds_raised_millions
        ) AS row_num
    FROM layoffs_2
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- MySQL does not allow deleting directly from a CTE, so we materialize the
-- row_num column into a real table (layoffs_3) and delete from that instead.
CREATE TABLE `layoffs_3` (
    `company` text,
    `location` text,
    `industry` text,
    `total_laid_off` int DEFAULT NULL,
    `percentage_laid_off` text,
    `date` text,
    `stage` text,
    `country` text,
    `funds_raised_millions` int DEFAULT NULL,
    row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_3
SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off,
                     percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
FROM layoffs_2;

-- Confirm duplicates exist before deleting
SELECT * FROM layoffs_3
WHERE row_num > 1;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM layoffs_3
WHERE row_num > 1;

-- ============================================================
-- #STEP 2: HANDLING NULLS AND BLANKS#
-- ============================================================

-- Convert blank strings to true NULLs
UPDATE layoffs_3
SET industry = NULL
WHERE industry = '';

-- Check for any remaining nulls/blanks
SELECT DISTINCT industry
FROM layoffs_3
WHERE industry IS NULL OR industry = '';

-- Preview rows where a company has both a NULL and a known industry value
SELECT * FROM layoffs_3 AS T1
JOIN layoffs_3 AS T2
    ON T1.company = T2.company
WHERE T1.industry IS NULL
  AND T2.industry IS NOT NULL;

-- fill NULL industry using another row with the same company that has a value
UPDATE layoffs_3 AS T1
JOIN layoffs_3 AS T2
    ON T1.company = T2.company
SET T1.industry = T2.industry
WHERE T1.industry IS NULL
  AND T2.industry IS NOT NULL;

-- identifying rows with no usable layoff signals
select * FROM layoffs_3
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
  
-- Remove rows with no usable layoff signals
DELETE FROM layoffs_3
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- ============================================================
-- STEP 3: STANDARDIZING DATA
-- ============================================================

-- Trim whitespace from company names
UPDATE layoffs_3
SET company = TRIM(company);

-- Collapse industry spelling variants (e.g. "Crypto", "Crypto Currency", "CryptoCurrency")
SELECT DISTINCT industry FROM layoffs_3;

UPDATE layoffs_3
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Fix "United States" vs "United States." trailing-period inconsistency
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) AS Country
FROM layoffs_3
ORDER BY 1;

UPDATE layoffs_3
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert date from text to a proper DATE type
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_3;

UPDATE layoffs_3
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_3
MODIFY COLUMN `date` DATE;


-- FINAL CHECK
SELECT * FROM layoffs_3;
