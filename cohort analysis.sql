---load the dataset
---total 541909 rows in dataset
/*select * from online_retail

---Cleaning the dataset
---because out data type is character varying we have to give null values as "" like this type of data 

delete * from  online_retail
where "CustomerID" = ''

select * from online_retail
--- deleting nun values and new data is with 406829 rows

-- lets change data type of quantity and unit price from character varying to numeric ignore if your datatype is numeric as before
ALTER TABLE online_retail
ALTER COLUMN "Quantity" TYPE numeric USING "Quantity"::numeric;

ALTER TABLE online_retail
ALTER COLUMN "UnitPrice" TYPE numeric USING "UnitPrice"::numeric;
*/
--- now we are starting making CTE so commenting out the above details will be helpful for running further CTEs(common table expressions)   
-- checking your positive numeric data of quantity and unit price
-- from 406829 rows, noe the updated rows are 397884
;with online_retail as
(
	select * from online_retail
	where "Quantity" > 0 and "UnitPrice" > 0 
)
, dup_check as
(
	-- 	duplicate check 
	select * ,ROW_NUMBER() over (partition by "InvoiceNo","StockCode","Quantity" order by "InvoiceDate")dup_flag
	from online_retail
	-- if "InvoiceNo","StockCode","Quantity" has same value occured it shows flag value will be > 1 for that row 
)

--clean data with 392669 rows
--5215 duplicate rows found
-- making one copy of a table

select * 
into new_online 
from dup_check where "dup_flag" =1 
-- cleaned data 
--begin cohort analysis

--making one table named cohort which has unique customer_id  
SELECT 
    "CustomerID", 
    MIN("InvoiceDate") AS first_purchase_date,
    CAST(DATE_TRUNC('MONTH', MIN("InvoiceDate")) AS TIMESTAMP WITH TIME ZONE) AS cohort_date
INTO cohort
FROM new_online 
GROUP BY "CustomerID";


select * from cohort
-- CREATING COHORT INDEX
-- now we will do a left join for which we can find diffrence between first purchase invoice date and recent purchase invoice date for that respected row  
-- so we can make year diffrence and month diffrence for that perticular purchase

select
	mmm.*,
	year_diff * 12 + month_diff + 1 as cohort_index
into cohort_retention	
from
	(
		select
			mm.*,
			invoice_year-cohort_year as year_diff,
			invoice_month-cohort_month as month_diff
		from
			(
				SELECT 
					m.*,
					c."cohort_date",
					EXTRACT(YEAR FROM m."InvoiceDate") AS invoice_year,
					EXTRACT(MONTH FROM m."InvoiceDate") AS invoice_month,
					EXTRACT(YEAR FROM c."cohort_date") AS cohort_year,
					EXTRACT(MONTH FROM c."cohort_date") AS cohort_month
				FROM new_online m
				LEFT JOIN cohort c
					ON m."CustomerID" = c."CustomerID"
			)mm
	)mmm
