# Layoffs Dataset — SQL Data Cleaning Project

## Overview
This project cleans a real-world "tech layoffs" dataset using MySQL. The raw data contained duplicate records, blank/inconsistent values, and text-formatted dates — all common issues in real business data. The goal was to turn it into a clean, analysis-ready table.

## Tools
- MySQL / MySQL Workbench

## Process

**1. Deduplication**
- Created a working copy of the raw table to preserve the original.
- Used `ROW_NUMBER()` with `PARTITION BY` across all key columns to flag duplicate rows.
- Since MySQL doesn't allow deleting directly from a CTE, materialized the row numbers into a new table and deleted duplicates from there.

**2. Handling Nulls and Blanks**
- Converted blank strings to proper `NULL` values.
- Used a self-join on `company` to identify rows missing an `industry` value where another row for the same company had one, then backfilled it.
- Removed rows with no usable signal (both `total_laid_off` and `percentage_laid_off` null).

**3. Standardizing**
- Trimmed whitespace from company names.
- Collapsed inconsistent industry naming (e.g. `Crypto`, `CryptoCurrency` → `Crypto`).
- Fixed inconsistent country values (e.g. `United States.` vs `United States`).
- Converted the date column from text to a proper `DATE` type using `STR_TO_DATE`.

## Files
- `layoffs_data_cleaning.sql` — full consolidated cleaning script

## Result
A deduplicated, standardized, analysis-ready table with correct data types, ready for downstream reporting or dashboarding (e.g. in Power BI or Tableau).
