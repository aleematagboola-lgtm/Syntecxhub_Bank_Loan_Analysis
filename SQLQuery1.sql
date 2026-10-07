CREATE DATABASE BankLoanDB;
GO

USE BankLoanDb;

SELECT COUNT(*) AS total_rows FROM bank_loan_data;

SELECT MIN(issue_date) AS first_date, MAX(issue_date) AS last_date FROM bank_loan_data;

SELECT loan_status, COUNT(*) AS cnt FROM bank_loan_data GROUP BY loan_status;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'bank_loan_data'
  AND COLUMN_NAME LIKE '%date%' OR COLUMN_NAME LIKE '%_dt';

USE BankLoanDb;

ALTER TABLE bank_loan_data
ADD issue_dt DATE, last_credit_pull_dt DATE, last_payment_dt DATE, next_payment_dt DATE;

UPDATE bank_loan_data
SET issue_dt            = CONVERT(DATE, issue_date, 105),
    last_credit_pull_dt = CONVERT(DATE, last_credit_pull_date, 105),
    last_payment_dt     = CONVERT(DATE, last_payment_date, 105),
    next_payment_dt     = CONVERT(DATE, next_payment_date, 105);

SELECT MIN(issue_dt) AS first_date, MAX(issue_dt) AS last_date FROM bank_loan_data;

ALTER TABLE bank_loan_data
DROP COLUMN issue_date, last_credit_pull_date, last_payment_date, next_payment_date;

EXEC sp_rename 'bank_loan_data.issue_dt',            'issue_date',            'COLUMN';
EXEC sp_rename 'bank_loan_data.last_credit_pull_dt', 'last_credit_pull_date', 'COLUMN';
EXEC sp_rename 'bank_loan_data.last_payment_dt',     'last_payment_date',     'COLUMN';
EXEC sp_rename 'bank_loan_data.next_payment_dt',     'next_payment_date',     'COLUMN';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'bank_loan_data' AND COLUMN_NAME LIKE '%date%';

--CORE KPIs

--3a. Total Loan Applications

SELECT COUNT(id) AS Total_Loan_Applications
FROM bank_loan_data;

--3b. Month-to-Date (MTD) Applications

SELECT COUNT(id) AS MTD_Total_Loan_Applications
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

--3c. Previous Month-to-Date (PMTD) Applications

SELECT COUNT(id) AS PMTD_Total_Loan_Applications
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;

--3d. Month-over-Month (MoM) change, and a heads-up

SELECT MIN(issue_date) AS first_dec_date, MAX(issue_date) AS last_dec_date
FROM bank_loan_data
WHERE MONTH(issue_date) = 12;

--3e. Total Funded Amount

SELECT SUM(loan_amount) AS Total_Funded_Amount
FROM bank_loan_data;

--MTD (December) and PMTD (November)

SELECT SUM(loan_amount) AS MTD_Total_Funded_Amount
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

SELECT SUM(loan_amount) AS PMTD_Total_Funded_Amount
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;

--3f. Total Amount Received

SELECT SUM(total_payment) AS Total_Amount_Received
FROM bank_loan_data;

--"Is the business growing or shrinking compared to last month?"

SELECT SUM(total_payment) AS MTD_Total_Amount_Received
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

SELECT SUM(total_payment) AS PMTD_Total_Amount_Received
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;

--3g. Average Interest Rate

SELECT ROUND(AVG(int_rate) * 100, 2) AS Avg_Interest_Rate
FROM bank_loan_data;

--MTD and PMTD

SELECT ROUND(AVG(int_rate) * 100, 2) AS MTD_Avg_Interest_Rate
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

SELECT ROUND(AVG(int_rate) * 100, 2) AS PMTD_Avg_Interest_Rate
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;

--3h. Average Debt-to-Income Ratio (DTI)

SELECT ROUND(AVG(dti) * 100, 2) AS Avg_DTI
FROM bank_loan_data;

--Is the bank lending to more stretched borrowers than last month?

SELECT ROUND(AVG(dti) * 100, 2) AS MTD_Avg_DTI
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

SELECT ROUND(AVG(dti) * 100, 2) AS PMTD_Avg_DTI
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;

--4a good loan %
--What share of our loans are performing well?

SELECT
    COUNT(CASE WHEN loan_status = 'Fully Paid' OR loan_status = 'Current' THEN id END) * 100.0
    / COUNT(id) AS Good_Loan_Percentage
FROM bank_loan_data;

--4b. Bad Loan Percentage

SELECT
    COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0
    / COUNT(id) AS Bad_Loan_Percentage
FROM bank_loan_data;

--Business question: "How much money is tied up in good loans and bad loans, and how much has come back from each?"

SELECT
    CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
         ELSE 'Bad Loan' END          AS Loan_Type,
    COUNT(id)                         AS Applications,
    SUM(loan_amount)                  AS Funded_Amount,
    SUM(total_payment)                AS Amount_Received
FROM bank_loan_data
GROUP BY CASE WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
              ELSE 'Bad Loan' END;

--Monthly Trend
--Business question: "How have applications, lending and repayments changed month by month through the year?" This shows whether the business is growing steadily, seasonal, or unstable.

SELECT
    MONTH(issue_date)              AS Month_Number,
    DATENAME(MONTH, issue_date)    AS Month_Name,
    COUNT(id)                      AS Total_Loan_Applications,
    SUM(loan_amount)               AS Total_Funded_Amount,
    SUM(total_payment)             AS Total_Amount_Received
FROM bank_loan_data
GROUP BY MONTH(issue_date), DATENAME(MONTH, issue_date)
ORDER BY MONTH(issue_date);

--

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

--Step 6: Region (state) analysis

--6a. Lending by state

SELECT
    address_state          AS State,
    COUNT(id)              AS Total_Loan_Applications,
    SUM(loan_amount)       AS Total_Funded_Amount,
    SUM(total_payment)     AS Total_Amount_Received
FROM bank_loan_data
GROUP BY address_state
ORDER BY SUM(loan_amount) DESC;

--Business question: "What percentage of all lending does each state account for?"

SELECT TOP 10
    address_state AS State,
    SUM(loan_amount) AS Total_Funded_Amount,
    ROUND(SUM(loan_amount) * 100.0 / (SELECT SUM(loan_amount) FROM bank_loan_data), 1) AS Pct_of_Total
FROM bank_loan_data
GROUP BY address_state
ORDER BY SUM(loan_amount) DESC;

--Business question: "Are some regions riskier than others?"

SELECT TOP 5
    address_state AS State,
    COUNT(id) AS Total_Loans,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY address_state
HAVING COUNT(id) >= 200
ORDER BY Bad_Loan_Pct DESC;

--

SELECT COUNT(id) AS Total_Loans,
       COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) AS Bad_Loans,
       ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct,
       SUM(CASE WHEN loan_status = 'Charged Off' THEN loan_amount END) AS Bad_Loan_Funded
FROM bank_loan_data
WHERE address_state = 'CA';

--What kinds of borrowers and loans does the bank have, and which types go bad most often?" This directly supports your brief's "factors affecting repayment" requirement, because it shows which characteristics go with defaults.

SELECT
    term                                   AS Loan_Term,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY term
ORDER BY term;

--Does job stability affect repayment?

SELECT
    emp_length                                   AS Loan_Length,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY emp_length
ORDER BY emp_length;

--What are people borrowing for, and which purposes are riskiest?

SELECT
    purpose                                  AS Loan_Purpose,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY purpose
ORDER BY purpose;

--Do renters, owners and mortgage holders behave differently?

SELECT
    home_ownership                                   AS Loan_owners,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY home_ownership
ORDER BY home_ownership;

--Question: "Do the borrowers who default look different from the ones who repay?"

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

--Question: "How well does the bank's own grading predict who defaults?"

SELECT
    grade                                       AS Grade,
    COUNT(id)                                   AS Total_Loans,
    ROUND(AVG(int_rate) * 100, 2)               AS Avg_Interest_Rate,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY grade
ORDER BY grade;

--Question: "Does being heavily indebted make a borrower more likely to default?"

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

--verification status

SELECT
    verification_status                    AS Verification_Status,
    COUNT(id)                              AS Total_Loan_Applications,
    SUM(loan_amount)                       AS Total_Funded_Amount,
    SUM(total_payment)                     AS Total_Amount_Received,
    ROUND(COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100.0 / COUNT(id), 1) AS Bad_Loan_Pct
FROM bank_loan_data
GROUP BY verification_status
ORDER BY verification_status;

