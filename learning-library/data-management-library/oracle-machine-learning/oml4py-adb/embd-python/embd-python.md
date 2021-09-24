# Store and manage Python objects and user-defined functions

## Introduction

This lab walks you through the steps to use OML4Py Embedded Python Execution functions as well as the Python Script Repository.

Estimated Lab Time: 20 minutes

### About Embedded Python Execution
Embedded Python Execution enables you to run user-defined Python functions in Python engines spawned in the Oracle Autonomous Database environment. These engines run alongside an OML Notebooks Python interpreter session.

The OML4Py Embedded Python Execution functions are:

* `oml.do_eval`&mdash;Calls a Python function in Python engines spawned by the Oracle Autonomous Database environment.
* `oml.group_apply`&mdash;Partitions a database table by the values in one or more columns and runs the provided user-defined Python function on each partition.
* `oml.index_apply`&mdash;Calls a Python function multiple times, passing in a unique index of the invocation to the user-defined function.
* `oml.row_apply`&mdash;Partitions a database table into sets of rows and runs the provided user-defined Python function on the data in each set.
* `oml.table_apply`&mdash;Calls a Python function on data in the database as a single pandas.DataFrame in a single Python engine.

> **Note:** Embedded Python Execution functions are also available through the [Oracle Machine Learning for Python REST API for Embedded Python Execution](https://docs.oracle.com/en/database/oracle/machine-learning/oml4py/1/mlepe/rest-endpoints.html).

### Objectives

In this lab, you will:
* Use the OML4Py Embedded Python Execution functions

## Download the notebook file for this Lab

1. [**CLICK HERE** to download the lab5\_embed\_python.json notebook file](./../notebooks/lab5_embed_python.json?download=1). This will download the notebook file for this lab to your local machine. 

2. Go back to the main notebooks listing by clicking on the "hamburger" menu (the three lines) on the upper left of the screen, and then select **Notebooks**.

 ![Oracle Machine Learning Notebooks menu](images/go-back-to-notebooks.png "Oracle Machine Learning Notebooks menu")

3. Click the **Import** button.  

 ![Oracle Machine Learning Notebooks import](images/click-on-import-notebook.png "Oracle Machine Learning Notebooks import")

4. Select the `lab5_embed_python.json` notebook file and click **Open**.
   
 ![Open Lab 5 JSON file](images/open-lab5-file.png "Open Lab 5 JSON file")

- After the notebook is successfully imported, click the **notebook name** to view it.
   ![Open Lab 5 notebook](images/click-on-lab5.png "Open Lab 5 notebook")

   OML Notebooks will create a session and make the notebook available for editing.

   You can optionally click the **Run all paragraphs** (![](images/run-all-paragraphs.png =20x*)) icon, and then click **OK** to confirm to refresh the content with your data, or just scroll down and read the pre-recorded results.  
   
   ![Lab 5 main screen](images/lab5-main.png "Lab 5 main screen")

## Task 1: Import OML4Py and Supporting Libraries and Create Data Table

Follow the flow of the notebook by scrolling to view and run each paragraph of this lab.

Scroll down to the beginning of Task 1.

  ![Lab 5 Task 1 screen](images/lab5-task1.png "Lab 5 Task 1 screen")  

## Task 2: Build and Score a Linear Model from sklearn in Python
Follow the flow of the notebook by scrolling to view and run each paragraph of this lab.

Scroll down to the beginning of Task 2.

  ![Lab 5 Task 2 screen](images/lab5-task2.png "Lab 5 Task 2 screen") 

## Task 3: Build the Model Using Embedded Python Execution
Follow the flow of the notebook by scrolling to view and run each paragraph of this lab.

Scroll down to the beginning of Task 3.

  ![Lab 5 Task 3 screen](images/lab5-task3.png "Lab 5 Task 3 screen") 

## Task 4: Build One Model per Species Using Group_Apply Function
Follow the flow of the notebook by scrolling to view and run each paragraph of this lab.

Scroll down to the beginning of Task 4.

  ![Lab 5 Task 4 screen](images/lab5-task4.png "Lab 5 Task 4 screen") 

## Task 5: Return Multiple Images from Embedded Python Execution
Follow the flow of the notebook by scrolling to view and run each paragraph of this lab.

Scroll down to the beginning of Task 5.

  ![Lab 5 Task 5 screen](images/lab5-task5.png "Lab 5 Task 5 screen") 


## Learn More

* [Embedded Python Execution](https://docs.oracle.com/en/database/oracle/machine-learning/oml4py/1/mlpug/embedded-python-execution.html#GUID-4FF75B48-6135-4219-A663-AFFBC0F4E9B6)
* [Oracle Machine Learning Notebooks](https://docs.oracle.com/en/database/oracle/machine-learning/oml-notebooks/)


## Acknowledgements
* **Author** - Marcos Arancibia, Product Manager, Machine Learning; Moitreyee Hazarika, Principal User Assistance Developer
* **Contributors** -  Mark Hornick, Senior Director, Data Science and Machine Learning; Sherry LaMonica, Principal Member of Tech Staff, Advanced Analytics, Machine Learning
* **Last Updated By/Date** - Moitreyee Hazarika, July 2021
