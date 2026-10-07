# Bank Loan Analysis

**Author:** Aleemat Agboola  


## Project Overview

This project looks at **38,576 bank loans issued in 2021** to understand how the bank's lending performed, where the risks are, and what areas may need closer attention.

I used **SQL Server** to prepare and analyze the data and **Power BI** to turn the results into an interactive dashboard.

The goal was not just to calculate numbers, but to answer simple business questions:

- How much is the bank lending?
  
- Is lending growing?
  
- How many loans are performing well?
  
- How much money is being lost through bad loans?
  
- Which types of loans and borrowers carry more risk?
  
- What actions could help the bank manage that risk?

---

## Table of Contents

1. Business Problem
   
2. Objectives
   
3. About the Data
   
4. Part 1: Preparing the Data
   
5. Part 2: Analysis in SQL
    
6. Part 3: Calculations in Power BI
    
7. The Dashboard
    
8. Key Findings
   
9. Recommendations
    
10. Project Files

---

# Business Problem

A bank lends money to many people throughout the year. To manage its lending effectively, the bank needs to understand both **growth and risk**.

This project focuses on three main questions:

1. **How is lending performing?**
   
   How many loans were issued, how much money was lent, and how much money has been received?

2. **How healthy is the loan portfolio?**

   How many loans are performing well, and how many have been charged off?

3. **Where is the risk?**
   
   Which loan types, credit grades, loan terms, regions and borrower characteristics are more strongly associated with bad loans?

The project turns the raw loan records into clear business insights and presents them through an interactive Power BI dashboard.

---

# Objectives

The main objectives of this project were to:

1. Understand the bank's lending activity and overall loan portfolio.
 
2. Calculate important business metrics such as total applications, funded amount and amount received.
 
3. Classify loans into good and bad loans based on their status.

4. Analyze lending trends over time.
 
5. Compare lending and loan risk across different states and customer characteristics.
 
6. Identify factors associated with bad loan outcomes.

7. Build an interactive Power BI dashboard that makes the findings easy to understand.
 
8. Provide recommendations based on the findings.

---

# About the Data

| Item | Details |
|---|---|
| **File** | `financial_loan.csv` |
| **Rows** | 38,576 loans |
| **Columns** | 24 |
| **Period** | 1 January 2021 to 12 December 2021 |
| **Unit of analysis** | One row represents one loan |

### Important Columns

| Column | Description |
|---|---|
| `loan_amount` | Amount of money the bank lent |
| `total_payment` | Amount of money received from borrowers |
| `loan_status` | Current status of the loan |
| `grade` | Credit grade assigned to the loan |
| `term` | Length of the loan, either 36 or 60 months |
| `purpose` | Reason for taking the loan |
| `int_rate` | Interest rate charged |
| `dti` | Debt-to-income ratio |
| `annual_income` | Borrower's yearly income |
| `address_state` | Borrower's state |
| `issue_date` | Date the loan was issued |

### Good Loans vs Bad Loans

| Category | Loan Status | Meaning |
|---|---|---|
| **Good Loan** | Fully Paid or Current | The borrower has paid the loan in full or is still making payments |
| **Bad Loan** | Charged Off | The loan is considered a loss because the bank has stopped expecting repayment |

---

# Preparing the Data

## Step 1: Load the Data into SQL Server

I created a database and imported the CSV file into a table called `bank_loan_data`.

```
CREATE DATABASE BankLoanDb;
GO
USE BankLoanDb;
```


Step 2: Fix the Date Columns

The date columns were initially stored as text rather than actual dates.

For example, dates such as 13-04-2021 were being treated as text. This could cause incorrect sorting and calculations.

I created new date columns, converted the text values into proper dates, checked the results, and then replaced the original columns.

**Add new date columns**

```
ALTER TABLE bank_loan_data
ADD issue_dt DATE, last_credit_pull_dt DATE, last_payment_dt DATE, next_payment_dt DATE;
```

**Convert the text into real dates**

```
UPDATE bank_loan_data
SET issue_dt            = CONVERT(DATE, issue_date, 105),
    last_credit_pull_dt = CONVERT(DATE, last_credit_pull_date, 105),
    last_payment_dt     = CONVERT(DATE, last_payment_date, 105),
    next_payment_dt     = CONVERT(DATE, next_payment_date, 105);
```

CONVERT changes the text into a proper date. The number 105 tells SQL that the original format is day-month-year.

**Check the converted dates**

```
SELECT MIN(issue_dt) AS first_date, MAX(issue_dt) AS last_date FROM bank_loan_data;
```

The result showed that the data covered 1 January 2021 to 12 December 2021, which confirmed that the conversion worked correctly.

**Remove the old columns and rename the new ones**

```
ALTER TABLE bank_loan_data
DROP COLUMN issue_date, last_credit_pull_date, last_payment_date, next_payment_date;

EXEC sp_rename 'bank_loan_data.issue_dt',            'issue_date',            'COLUMN';
EXEC sp_rename 'bank_loan_data.last_credit_pull_dt', 'last_credit_pull_date', 'COLUMN';
EXEC sp_rename 'bank_loan_data.last_payment_dt',     'last_payment_date',     'COLUMN';
EXEC sp_rename 'bank_loan_data.next_payment_dt',     'next_payment_date',     'COLUMN';
```

**Check the Data**

Before starting the analysis, I checked that the data had loaded correctly.

-- How many loans?
```
SELECT COUNT(*) AS total_rows FROM bank_loan_data;

-- What dates does the data cover?
SELECT MIN(issue_date) AS first_date, MAX(issue_date) AS last_date FROM bank_loan_data;

-- What loan statuses are there?
SELECT loan_status, COUNT(*) AS cnt FROM bank_loan_data GROUP BY loan_status;

-- Are the date columns now real dates?
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'bank_loan_data';
```


# Analysis in SQL

SQL was used to answer the main business questions and calculate the numbers that would later be used in the Power BI dashboard.

For the monthly comparison, December represents the latest month and November represents the previous month.

**Key Business Metrics

**Total Loan Applications**

Question: How many loans did the bank issue?

```
SELECT COUNT(id) AS Total_Loan_Applications
FROM bank_loan_data;
December
SELECT COUNT(id) AS MTD_Total_Loan_Applications
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;
November
SELECT COUNT(id) AS PMTD_Total_Loan_Applications
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;
```

**Total Funded Amount**

Question: How much money did the bank lend?

```
SELECT SUM(loan_amount) AS Total_Funded_Amount FROM bank_loan_data;

SELECT SUM(loan_amount) AS MTD_Total_Funded_Amount
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

SELECT SUM(loan_amount) AS PMTD_Total_Funded_Amount
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;
```

**Total Amount Received**

Question: How much money has the bank received from borrowers?

```
SELECT SUM(total_payment) AS Total_Amount_Received FROM bank_loan_data;

SELECT SUM(total_payment) AS MTD_Total_Amount_Received
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

SELECT SUM(total_payment) AS PMTD_Total_Amount_Received
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;
```

**Average Interest Rate**

Question: What interest rate does the bank charge on average?

```
SELECT ROUND(AVG(int_rate) * 100, 2) AS Avg_Interest_Rate
FROM bank_loan_data;

SELECT ROUND(AVG(int_rate) * 100, 2) AS MTD_Avg_Interest_Rate
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

SELECT ROUND(AVG(int_rate) * 100, 2) AS PMTD_Avg_Interest_Rate
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;
```

**Average Debt-to-Income Ratio**

Question: How much debt do borrowers have compared with their income?
```
SELECT ROUND(AVG(dti) * 100, 2) AS Avg_DTI FROM bank_loan_data;

SELECT ROUND(AVG(dti) * 100, 2) AS MTD_Avg_DTI
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

SELECT ROUND(AVG(dti) * 100, 2) AS PMTD_Avg_DTI
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;
```

**Good Loans and Bad Loans**

**Good Loan Percentage**

Question: What percentage of loans are performing well?
```
SELECT
    COUNT(CASE WHEN loan_status = 'Fully Paid' OR loan_status = 'Current' THEN id END) * 100.0
    / COUNT(id) AS Good_Loan_Percentage
FROM bank_loan_data;
```


**Bad Loan Percentage**

Question: What percentage of loans have been charged off?
```
SELECT
    COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0
    / COUNT(id) AS Bad_Loan_Percentage
FROM bank_loan_data;
```


**Good Loans vs Bad Loans**
```
SELECT
    CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
         ELSE 'Bad Loan' END          AS Loan_Type,
    COUNT(id)                         AS Applications,
    SUM(loan_amount)                  AS Funded_Amount,
    SUM(total_payment)                AS Amount_Received
FROM bank_loan_data
GROUP BY CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
              ELSE 'Bad Loan' END;
```


**Changes Over Time**

**Monthly Lending Trend**

Question: How did applications, lending and payments change throughout the year?
```
SELECT
    MONTH(issue_date)              AS Month_Number,
    DATENAME(MONTH, issue_date)    AS Month_Name,
    COUNT(id)                      AS Total_Loan_Applications,
    SUM(loan_amount)               AS Total_Funded_Amount,
    SUM(total_payment)             AS Total_Amount_Received
FROM bank_loan_data
GROUP BY MONTH(issue_date), DATENAME(MONTH, issue_date)
ORDER BY MONTH(issue_date);
```

**Which Month Grew the Most?**
```
WITH monthly AS (
    SELECT MONTH(issue_date) AS m, COUNT(id) AS apps
    FROM bank_loan_data
    GROUP BY MONTH(issue_date)
)
SELECT m,
       apps,
       apps - LAG(apps) OVER (ORDER BY m) AS change_from_prev,
       ROUND((apps - LAG(apps) OVER (ORDER BY m)) * 100.0 / LAG(apps) OVER (ORDER BY m), 1) AS pct_change
FROM monthly
ORDER BY m;
```

**Regional Analysis**

**Lending by State**
```
SELECT
    address_state          AS State,
    COUNT(id)              AS Total_Loan_Applications,
    SUM(loan_amount)       AS Total_Funded_Amount,
    SUM(total_payment)     AS Total_Amount_Received
FROM bank_loan_data
GROUP BY address_state
ORDER BY SUM(loan_amount) DESC;
```

**State Share of Total Lending**
```
SELECT TOP 10
    address_state AS State,
    SUM(loan_amount) AS Total_Funded_Amount,
    ROUND(SUM(loan_amount) * 100.0 / (SELECT SUM(loan_amount) FROM bank_loan_data), 1) AS Pct_of_Total
FROM bank_loan_data
GROUP BY address_state
ORDER BY SUM(loan_amount) DESC;
```

**States with the Highest Bad Loan Rates**
```
SELECT TOP 5
    address_state AS State,
    COUNT(id) AS Total_Loans,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY address_state
HAVING COUNT(id) >= 200
ORDER BY Bad_Loan_Pct DESC;
```


**Is the Biggest State Also the Riskiest?**
```
SELECT COUNT(id) AS Total_Loans,
       COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) AS Bad_Loans,
       ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct,
       SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount END) AS Bad_Loan_Funded
FROM bank_loan_data
WHERE address_state = 'CA';
```

**Customer and Loan Characteristics**

**Loan Term**
```
SELECT
    term                                   AS Loan_Term,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY term
ORDER BY term;
```


**Employment Length**
```
SELECT
    emp_length                             AS Employment_Length,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY emp_length
ORDER BY emp_length;
```

**Loan Purpose**
```
SELECT
    purpose                                AS Loan_Purpose,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY purpose
ORDER BY SUM(loan_amount) DESC;
```

**Home Ownership**

```
SELECT
    home_ownership                         AS Home_Ownership,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY home_ownership
ORDER BY home_ownership;
```

**Income Verification**
```
SELECT
    verification_status                    AS Verification_Status,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY verification_status
ORDER BY verification_status;
```

**What Affects Repayment?**

**Good Loans vs Bad Loans**
```
SELECT
    CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
         ELSE 'Bad Loan' END                    AS Loan_Type,
    ROUND(AVG(int_rate) * 100, 2)               AS Avg_Interest_Rate,
    ROUND(AVG(dti) * 100, 2)                    AS Avg_DTI,
    ROUND(AVG(annual_income), 0)                AS Avg_Annual_Income,
    ROUND(AVG(loan_amount), 0)                  AS Avg_Loan_Amount
FROM bank_loan_data
GROUP BY CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
              ELSE 'Bad Loan' END;
```


**Credit Grade and Bad Loans**
```
SELECT
    grade                                       AS Grade,
    COUNT(id)                                   AS Total_Loans,
    ROUND(AVG(int_rate) * 100, 2)               AS Avg_Interest_Rate,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY grade
ORDER BY grade;
```

**Debt-to-Income Ratio**
```
WITH banded AS (
    SELECT *,
        CASE WHEN dti < 0.10 THEN '1. Under 10%'
             WHEN dti < 0.15 THEN '2. 10% to 15%'
             WHEN dti < 0.20 THEN '3. 15% to 20%'
             ELSE '4. 20% and above' END AS DTI_Band
    FROM bank_loan_data
)
SELECT
    DTI_Band,
    COUNT(id) AS Total_Loans,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM banded
GROUP BY DTI_Band
ORDER BY DTI_Band;
```


# Calculations in Power BI

SQL provided the initial analysis, but Power BI was used to create an interactive dashboard.

This means users can select a month, state, loan grade or other category and see the numbers update automatically.

I also used the SQL results as a reference point to check that my Power BI calculations were producing the correct results.

**Calendar Table**

I created a calendar table covering the full year.
```
Date = CALENDAR(DATE(2021,1,1), DATE(2021,12,31))
Month Number = MONTH('Date'[Date])
Month Name = FORMAT('Date'[Date], "MMM")
```

The month number was used to make sure months appeared in the correct calendar order.

I then connected the calendar table to the loan table using the loan issue date.

**Basic Measures**

Total Loan Applications
```
Total Loan Applications = COUNT(bank_loan_data[id])
```

Total Funded Amount
```
Total Funded Amount = SUM(bank_loan_data[loan_amount])
```

Total Amount Received
```
Total Amount Received = SUM(bank_loan_data[total_payment])
```
Average Interest Rate
```
Avg Interest Rate = AVERAGE(bank_loan_data[int_rate])
```
Average 
```
Avg DTI = AVERAGE(bank_loan_data[dti])
```
Average Loan Amount
```
Avg Loan Amount = AVERAGE(bank_loan_data[loan_amount])
```
Average Annual Income
```
Avg Annual Income = AVERAGE(bank_loan_data[annual_income])
```

Selected Month
```
Selected Month = MAX('Date'[Month Number])
```
This measure identifies the month selected on the dashboard.

**Latest Month, Previous Month and Month-on-Month Change**

Applications
```
MTD Applications =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Total Loan Applications], 'Date'[Month Number] = SelMonth)
```

```
PMTD Applications =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Total Loan Applications], REMOVEFILTERS('Date'), 'Date'[Month Number] = SelMonth - 1)
```

```
MoM Applications = DIVIDE([MTD Applications] - [PMTD Applications], [PMTD Applications])
```

Funded Amount
```
MTD Funded Amount =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Total Funded Amount], 'Date'[Month Number] = SelMonth)
```

```
PMTD Funded Amount =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Total Funded Amount], REMOVEFILTERS('Date'), 'Date'[Month Number] = SelMonth - 1)
```

```
MoM Funded Amount = DIVIDE([MTD Funded Amount] - [PMTD Funded Amount], [PMTD Funded Amount])
```

Amount Received
```
MTD Amount Received =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Total Amount Received], 'Date'[Month Number] = SelMonth)
```

```
PMTD Amount Received =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Total Amount Received], REMOVEFILTERS('Date'), 'Date'[Month Number] = SelMonth - 1)
```

```
MoM Amount Received = DIVIDE([MTD Amount Received] - [PMTD Amount Received], [PMTD Amount Received])
```

Average Interest Rate

```
MTD Avg Interest Rate =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Avg Interest Rate], 'Date'[Month Number] = SelMonth)
```

```
PMTD Avg Interest Rate =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Avg Interest Rate], REMOVEFILTERS('Date'), 'Date'[Month Number] = SelMonth - 1)
```

```
MoM Avg Interest Rate = DIVIDE([MTD Avg Interest Rate] - [PMTD Avg Interest Rate], [PMTD Avg Interest Rate])
```


Average DTI

```
MTD Avg DTI =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Avg DTI], 'Date'[Month Number] = SelMonth)
```

```
PMTD Avg DTI =
VAR SelMonth = [Selected Month]
RETURN
    CALCULATE([Avg DTI], REMOVEFILTERS('Date'), 'Date'[Month Number] = SelMonth - 1)
```

```
MoM Avg DTI = DIVIDE([MTD Avg DTI] - [PMTD Avg DTI], [PMTD Avg DTI])
```

Good Loan and Bad Loan Measures
```
Good Loan Applications =
CALCULATE([Total Loan Applications], bank_loan_data[loan_status] IN {"Fully Paid", "Current"})
```

```
Bad Loan Applications =
CALCULATE([Total Loan Applications], bank_loan_data[loan_status] = "Charged Off")
```

```
Good Loan % = DIVIDE([Good Loan Applications], [Total Loan Applications])
```

```
Bad Loan % = DIVIDE([Bad Loan Applications], [Total Loan Applications])
```

```
Good Loan Funded Amount =
CALCULATE([Total Funded Amount], bank_loan_data[loan_status] IN {"Fully Paid", "Current"})
```

```
Good Loan Received Amount =
CALCULATE([Total Amount Received], bank_loan_data[loan_status] IN {"Fully Paid", "Current"})
```

```
Bad Loan Funded Amount =
CALCULATE([Total Funded Amount], bank_loan_data[loan_status] = "Charged Off")
```

```
Bad Loan Received Amount =
CALCULATE([Total Amount Received], bank_loan_data[loan_status] = "Charged Off")
```

**Additional Power BI Columns**

For some visuals, I created two additional columns.

Loan Category
```
Loan Category = IF(bank_loan_data[loan_status] IN {"Fully Paid", "Current"}, "Good Loan", "Bad Loan")
```

DTI Band
```
DTI Band =
SWITCH(
    TRUE(),
    bank_loan_data[dti] < 0.10, "1. Under 10%",
    bank_loan_data[dti] < 0.15, "2. 10% to 15%",
    bank_loan_data[dti] < 0.20, "3. 15% to 20%",
    "4. 20% and above"
)
```


# The Dashboard

The final Power BI dashboard contains four pages designed to tell the story from overall performance to detailed risk insights.

**Page 1: Summary**

The Summary page provides a quick view of the bank's overall lending activity.

It includes:

Total loan applications

Total funded amount

Total amount received

Average interest rate

Average DTI

Monthly lending trends

Loan status

Loan grade

Loan purpose

Dashboard Screenshot:

Add screenshot here

**Page 2: Overview and Borrowers**

This page focuses on the people taking the loans and the characteristics of their loans.

It includes analysis of:

Borrower profile

Income

Employment length

Home ownership

Loan purpose

Verification status

Loan characteristics

Dashboard Screenshot:

Add screenshot here

**Page 3: Loan Quality and Risk** 

This page focuses on the quality of the loan portfolio and the areas where risk is higher.

It includes:

Good vs bad loans

Loan grades

Loan terms

Bad loan rates

Loan purposes

DTI

Regional risk

Dashboard Screenshot:

Add screenshot here

**Page 4: Insights and Recommendations**

This page brings the analysis together into simple business insights and recommended actions.

It highlights:

Lending growth

Major risk areas

High-risk loan categories

Regional observations

Opportunities for better risk management

Recommended actions for the bank

Dashboard Screenshot:

Add screenshot here

# Key Findings
   
**Lending is Growing**

1. The bank lent $435.8M across 38,576 loans and received $473.1M.

2. Applications increased from 2,332 in January to 4,314 in December.

3. March recorded the largest month-on-month increase at 15.3%.

4. The amount lent increased from $25.0M in January to $54.0M in December.

5. From November to December, applications increased by 6.9%, while the amount lent increased by 13.0%.

6. The average interest rate increased by 3.5%, while average DTI increased by 2.7%.

This shows strong lending growth, but the increase in interest rates and borrower debt levels should also be monitored.

**Good Loans vs Bad Loans**

1. 86.2% of loans are classified as good loans.

2. 13.8% are classified as bad loans.

3. Good loans generated $435.8M from $370.2M lent.

4. Bad loans generated only $37.3M from $65.5M lent.

This represents approximately $28.2M in losses from bad loans.

**Where the Risk Is**

**Credit Grade**

Bad loan rates increase significantly across credit grades:

Grade A: 5.7%

Grade C: 16.0%

Grade E: 24.8%

Grade G: 31.3%

This makes credit grade one of the strongest risk indicators in the dataset.

**Loan Term**

60-month loans have a 22.3% bad loan rate compared with 10.7% for 36-month loans.

**Loan Purpose**

Small business loans have the highest bad loan rate at 25.6%.

**Region**

California accounts for approximately 18% of total lending and has the largest total amount of money tied to bad loans.

Nevada has the highest bad loan rate among the larger states at 21.0%, while Florida has a high rate of 17.3%.

**Debt-to-Income Ratio**

Bad loan rates increase from 12.0% among borrowers with DTI below 10% to 15.6% among borrowers with DTI of 20% or higher.

The relationship exists, but it is weaker than the patterns seen with credit grade and loan term.

**Factors with Little Difference**

Homeownership and employment length show relatively small differences in bad loan rates.

# Recommendations

**1. Give More Attention to High-Risk Loan Categories**

a. Grades E to G have bad loan rates between 24.8% and 31.3%.

b. Small business loans also have a high bad loan rate of 25.6%.

c. The bank could apply additional checks or risk controls to these categories.

**2. Review 60-Month Loans**

a. 60-month loans have more than twice the bad loan rate of 36-month loans.

b. The bank could review the conditions attached to longer-term loans and consider whether additional risk checks are needed.

**3. Monitor High-Risk Regions**

a. Nevada and Florida have relatively high bad loan rates, while California has the largest total exposure because of its lending volume.

b. Regional monitoring could help the bank identify changes in risk early.

**4. Continue Supporting Lower-Risk Loan Types**

a. Some loan purposes have lower bad loan rates than the overall portfolio.

For example:

Credit card: 10.2%

Home improvement: 11.4%

b. The bank could continue monitoring these categories while maintaining appropriate lending standards.

**5. Monitor Growth Alongside Risk**

a. The bank's lending activity is growing strongly, but some risk indicators are also increasing.

b. As lending grows, the bank should continue monitoring:

Credit grade

Loan term

Loan purpose

DTI

Regional risk

Bad loan rates

This can help the bank grow its lending portfolio without allowing loan losses to increase at the same pace.

**Final Takeaway**

The analysis shows a bank with strong lending growth, but also highlights areas where risk needs closer attention.

The strongest risk signals in this dataset are lower credit grades, longer loan terms and small business loans. The bank also has significant exposure in California and relatively high bad loan rates in states such as Nevada and Florida.

The main opportunity is therefore not simply to increase lending, but to grow while maintaining strong risk controls.

# Project Files

File	Description
financial_loan.csv	Original loan dataset

Bank_Loan_Analysis.sql	SQL queries used for data preparation and analysis

Bank_Loan_Analysis.pbix	Interactive Power BI dashboard


# Tools Used

MSSQL Server - Data preparation, validation and analysis

Power BI - Data modeling, DAX calculations and dashboard development

DAX - Interactive measures and calculations

GitHub - Project documentation and portfolio presentation

# Key Skills Demonstrated

Data cleaning and validation

SQL querying

Business analysis

KPI development

DAX measures

Data modeling

Time-based analysis

Risk analysis

Dashboard design

Insight generation

Business recommendations

