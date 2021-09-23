# Initializing Labs

## Introduction
The workshop assumes that an Oracle Machine Learning user named `OMLUSER` has been created and configured for signing into OML Notebooks and runing all Tasks, and that a set of sample Tables have been loaded into that schema. 

**IMPORTANT:** This user is not available by default in any Autonomous Database tenancy.  

Please follow the steps below to make sure you have this user and the sample data created in your tenancy prior to running the Labs. 

The SQL scripts will drop and recreate the OMLUSER user.  This means that all of the data for that user will be deleted and recreated.

>**<span style="color:red">Warning:</span>  Any custom work that you did previously in the OMLUSER schema will be deleted - so save your work!**

Estimated Time: 5 minutes

## Task 1:  Connect to the ADB SQL Tool as the ADMIN User

Connect to Autonomous Database tool as the ADMIN user:

1. In your ADW database's details page, click the Tools tab. Click **Open Database Actions**.

    ![Click on Tools, then Database Actions](images/launchdbactions.png " ")

2. On the login screen, enter the username ADMIN, then click the blue **Next** button.

3. Enter the password for the ADMIN user you set up in the provisioning lab.

4. Open the SQL Worksheet from the Launchpad:

    ![Click on SQL from the Launchpad](images/launchpad.png " ")

## Task 2:  Create the PL/SQL Procedures that Run the Prerequisite Labs

Now that you're in the SQL worksheet, you will create the procedures used to initialize the labs.  

1. Copy the script below into the worksheet and click Run Script (F5).

```
<copy>
-- The following commands should be run before running the Labs, 
-- since it creates some tables and grants access to any users of the PDB.

-- Click F5 to run all the scripts at once

-- Drop the schema OMLUSER
BEGIN
       EXECUTE IMMEDIATE 'DROP USER OMLUSER CASCADE';
       EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Drop the schema OMLUSER2
BEGIN
       EXECUTE IMMEDIATE 'DROP USER OMLUSER2 CASCADE';
       EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE USER OMLUSER IDENTIFIED BY "AAbbcc123456";
GRANT DWROLE TO OMLUSER;
GRANT OML_DEVELOPER TO OMLUSER;
ALTER USER OMLUSER GRANT CONNECT THROUGH OML$PROXY;
ALTER USER OMLUSER QUOTA UNLIMITED on DATA;

CREATE USER OMLUSER2 IDENTIFIED BY "AAbbcc123456";
GRANT DWROLE TO OMLUSER2;
GRANT OML_DEVELOPER TO OMLUSER2;
ALTER USER OMLUSER2 GRANT CONNECT THROUGH OML$PROXY;
ALTER USER OMLUSER2 QUOTA UNLIMITED on DATA;

-- Create the CUSTOMER_INSURANCE_LTV table based on an external table
DECLARE
     uri_data varchar2(1000) := 'https://raw.githubusercontent.com/oracle/oracle-db-examples/master/machine-learning/datasets/CUST_INSUR_LTV_APPLY.csv';
     csv_format varchar2(1000) := '{"dateformat":"YYYY-MM-DD", "skipheaders":"1", "delimiter":",", "ignoreblanklines":"true", "removequotes":"true", "blankasnull":"true", "trimspaces":"lrtrim", "truncatecol":"true", "ignoremissingcolumns":"true"}';
BEGIN
    BEGIN
       EXECUTE IMMEDIATE 'DROP TABLE EXT_CUSTOMER_INSURANCE_LTV';
       EXCEPTION WHEN OTHERS THEN NULL;
    END;

    DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
            TABLE_NAME => 'EXT_CUSTOMER_INSURANCE_LTV',
            FILE_URI_LIST => uri_data,
            FORMAT => csv_format,
            COLUMN_LIST => 'MARITAL_STATUS          VARCHAR2(26),
                            STATE                   VARCHAR2(26),
                            CREDIT_BALANCE          NUMBER(8,0),
                            CUSTOMER_TENURE         NUMBER(3,0),
                            MORTGAGE_AMOUNT         NUMBER(7,0),
                            BANK_FUNDS              NUMBER(7,0),
                            NUM_DEPENDENTS          NUMBER(3,0),
                            HAS_CHILDREN            NUMBER(3,0),
                            INCOME                  NUMBER(7,0),
                            CUSTOMER_ID             VARCHAR2(26),
                            GENDER                  VARCHAR2(26),
                            PROFESSION              VARCHAR2(35),
                            CREDIT_CARD_LIMITS      NUMBER(6,0),
                            REGION                  VARCHAR2(26),
                            HOME_OWNERSHIP          NUMBER(3,0),
                            NUM_ONLINE_TRANS        NUMBER(6,0),
                            BUY_INSURANCE           VARCHAR2(26),
                            MONTHLY_CHECKS          NUMBER(4,0),
                            NUM_TRANS_KIOSK         NUMBER(3,0),
                            AGE                     NUMBER(4,0),
                            MONEY_MONTLY_OVERDRAWN  NUMBER(6,2),
                            LTV                     NUMBER(9,2),
                            TOTAL_AUTOM_PAYMENTS    NUMBER(8,0),
                            NUM_TRANS_TELLER        NUMBER(3,0),
                            CHECKING_BALANCE        NUMBER(7,0),
                            NUM_TRANS_ATM           NUMBER(3,0),
                            LTV_BIN                 VARCHAR2(26),
                            FIRST_NAME              VARCHAR2(26),
                            NUM_MORTGAGES           NUMBER(3,0),
                            CAR_OWNERSHIP           NUMBER(3,0),
                            LAST_NAME               VARCHAR2(26)');

-- WRITE A TABLE INTO THE CURRENT USER WITH THE NAME "CUSTOMER_INSURANCE_LTV"    

END;
 /

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE OMLUSER.CUSTOMER_INSURANCE_LTV';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE OMLUSER.CUSTOMER_INSURANCE_LTV AS SELECT * FROM EXT_CUSTOMER_INSURANCE_LTV;

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE OMLUSER.CUSTOMER_INSURANCE_LTV_NOISE';
    EXCEPTION WHEN OTHERS THEN NULL;
END;
/
-- Create a Noisy Data out of the original
CREATE TABLE OMLUSER.CUSTOMER_INSURANCE_LTV_NOISE AS
SELECT * FROM OMLUSER.CUSTOMER_INSURANCE_LTV;

UPDATE OMLUSER.CUSTOMER_INSURANCE_LTV_NOISE
SET INCOME = NULL, BANK_FUNDS = NULL, CREDIT_BALANCE = NULL, MARITAL_STATUS = NULL
WHERE CUSTOMER_ID < 'CU2';

INSERT INTO OMLUSER.CUSTOMER_INSURANCE_LTV_NOISE
VALUES (NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

CREATE OR REPLACE view OMLUSER.CUSTOMER_INSURANCE_LTV_VIEW AS 
SELECT * from OMLUSER.CUSTOMER_INSURANCE_LTV;

GRANT SELECT ON OMLUSER.CUSTOMER_INSURANCE_LTV TO PUBLIC;  
GRANT SELECT ON OMLUSER.CUSTOMER_INSURANCE_LTV_NOISE TO PUBLIC;  
GRANT SELECT ON OMLUSER.CUSTOMER_INSURANCE_LTV_VIEW TO PUBLIC;    

 </copy>
```

2. The result of running the procedure is displayed below. There is a new table called MOVIESTREAM_LABS that contains the list of available labs in this workshop.

    ![Running the script](images/run-script.png)

    This may take a few minutes to run; the script is running thru many steps. 
    Once completed, users OMLUSER and OMLUSER2 are initialized and you can continue to `Lab 0: Run Me First - OML4Py table creation and grants`.

## Acknowledgements

* **Author** - Marcos Arancibia, Product Manager, Machine Learning
* **Last Updated By/Date** - Marcos Arancibia, September 2021
