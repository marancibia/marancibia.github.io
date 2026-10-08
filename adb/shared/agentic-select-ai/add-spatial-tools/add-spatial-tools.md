# Enhance the the Return Agent with store location  

## Introduction

This lab focuses on refining the solution of the previous labs to achieve a better customer experience by providing an option to drive to the closest store to the customer.  

In this lab, you’ll enhance the table `customers` with a complete address, add a new `stores` table containing the addresses of a few stores, and experience the more complete answers from the Agent.

Estimated Time: 20 minutes

### Objectives

In this lab, you will:

* Replace the `customers` table with a more complete address
* Create a new `stores` table with the store addresses
* Create new `find_local_pickup` procedure to identify the closest stores to a customer
* Add the new task to the Return Agency Team.
* Run an end-to-end test and review the generated answers.

### Prerequisites

- This lab requires completion of Lab 1 and Lab 2 in the **Contents** menu on the left.

> Note: If you are independently using OML Notebook on your instance to run the code, append `%script` at the beginning for the codeblocks.

## Task 1: Enhance Customer table with precise addresses, and add Store tables

We'll enhance the `customers` table with additional details on each customer's street address. The address is then geocoded into a spatial geometry, so the agent can later calculate drive times to nearby stores.

1. Run the paragraph that creates `customers` table. The `UPDATE` statement at the end geocodes each address with `SDO_GCDR.ELOC_GEOCODE_AS_GEOM` and stores the result in the `geometry` column.
    ```
    <copy>
  
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE customers';
    EXCEPTION WHEN OTHERS THEN NULL; END;
    /
    CREATE TABLE customers (
        customer_id  NUMBER(10) PRIMARY KEY,
        name         VARCHAR2(100),
        email        VARCHAR2(100),
        phone        VARCHAR2(20),
        address      VARCHAR2(100)
    );

    INSERT INTO customers (customer_id, name, email, phone, address) VALUES
    (1, 'Alice Thompson', 'alice.thompson@example.com','555-1234', '104 Chestnut St, Albany NY, 12210'),
    (2, 'Bob Martinez',   'bob.martinez@example.com',  '555-2345', '4825 Willowbrook Dr, Sacramento CA 95842'),
    (3, 'Carol Chen',     'carol.chen@example.com',    '555-3456', '1623 Alston Ave, Fort Worth TX, 73301'),
    (4, 'David Johnson',  'david.johnson@example.com', '555-4567', '807 S Warren St, Peoria IL, 61605'),
    (5, 'Eva Green',      'eva.green@example.com',     '555-5678', '10 Pittwick Ln, Palm Coast FL, 32164');

    alter table customers add (geometry sdo_geometry);

    -- Geocode customer addresses into spatial geometries for drive-time calculations.
    update customers set geometry = sdo_gcdr.eloc_geocode_as_geom(address) ;
    </copy>
    ```

2. View the contents of the `customers` table. 

    ```
    <copy>
    select * from customers;
    </copy>
    ```

3. Run the paragraph that creates `stores` table. Each store has a name and a location, stored as longitude and latitude. The stores are spread across the same cities as the customers, so each customer has at least one store nearby.

    ```
    <copy>
  
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE stores';
    EXCEPTION WHEN OTHERS THEN NULL; END;
    /
    CREATE TABLE stores (
        store_id  NUMBER(10) PRIMARY KEY,
        store_name VARCHAR2(30),   
        longitude NUMBER,
        latitude  NUMBER
    );
    /

    INSERT INTO stores VALUES
    (1,'Albany Downtown Mall',-73.8326, 42.6220),
    (2,'North Greenbush Plaza',-73.6918, 42.7284),
    (3,'Capital District Center',-73.9288, 42.6537),
    (4,'Hudson Valley Outlet',-73.8168, 42.4734),
    (5,'Catskill Commons',-73.7920, 42.2529),
    (6,'Folsom Mall',-121.2715, 38.7397),
    (7,'Sacramento River Center',-121.5564, 38.7071),
    (8,'Gold Country Plaza',-121.0800, 38.8400),
    (9,  'Fort Worth Stockyards Center', -97.3489, 32.7873),
    (10, 'West 7th Fort Worth Plaza',     -97.3652, 32.7528),
    (11, 'Peoria Riverfront Center',      -89.5889, 40.6936),
    (12, 'Northwoods Mall Peoria',        -89.6107, 40.7584),
    (13, 'Palm Coast Town Center',        -81.2078, 29.5554),
    (14, 'Flagler Beach Marketplace',     -81.1311, 29.4743);
    </copy>
    ```

6. View the stores table.

    ```
    <copy>
    select * from stores;
    </copy>
    ```

## Task 3: Create the Order Status and Local Pickup Functions

You will create a SQL function to update a customer’s order status and return a message, run an PL/SQL block to set a customers order to _pending\_return_ and print the result, then verify the table. Then, you will create a second function that finds the closest store for local pickup and test it.

1. Create a customer order update status function.

    ```
    <copy>
    
    CREATE OR REPLACE FUNCTION update_customer_order_status (
    p_customer_name IN VARCHAR2,
    p_order_number  IN VARCHAR2,
    p_status        IN VARCHAR2
    ) RETURN CLOB IS
    v_customer_id  customers.customer_id%TYPE;
    v_row_count    NUMBER;
    BEGIN
    -- Find customer_id from customer_name
    SELECT customer_id
    INTO v_customer_id
    FROM customers
    WHERE name = p_customer_name;
    
    UPDATE customer_order_status
    SET status = p_status
    WHERE customer_id = v_customer_id
      AND order_number = p_order_number;

    v_row_count := SQL%ROWCOUNT;

    IF v_row_count = 0 THEN
        RETURN 'No matching record found to update.';
    ELSE
        RETURN 'Update successful.';
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
    END;
    </copy>
    ```
2. Test this function by updating an order for a specific customer and return a message on completion.

    ```
    <copy>
    
    DECLARE
      v_result CLOB;
    BEGIN
      v_result := update_customer_order_status('David Johnson', '3928', 'pending_return');

      DBMS_OUTPUT.PUT_LINE(v_result);
    END;
    </copy>
    ```
3. Verify the change by viewing the customer order update status table for that customer. 

    ```
    <copy>
    select * from customer_order_status
    where ORDER_NUMBER = 3928
    </copy>
    ```

4. Create a function that finds the closest store for local pickup. The function works in three steps:

    * It builds a drive-time polygon around the customer's address with `SDO_GCDR.ELOC_DRIVE_TIME_POLYGON`. The polygon covers the area reachable within 45 minutes by car.
    * It counts the stores that fall inside that polygon.
    * It ranks those stores by route drive time with `SDO_GCDR.ELOC_ROUTE_TIME`, and returns the closest store and its drive time.

    ```
    <copy>
    
    CREATE OR REPLACE FUNCTION find_local_pickup (
      p_customer_name IN VARCHAR2,
      p_order_number  IN NUMBER
    ) RETURN CLOB IS
      isochrone       SDO_GEOMETRY;
      out_store_name  stores.store_name%TYPE;
      out_drive_time  NUMBER;
      out_nstores     NUMBER;
    BEGIN
      -- Step 1: Build a drive-time polygon around the customer's address.
      -- This polygon represents the geographic area reachable within 45 minutes by car.
      SELECT SDO_GCDR.ELOC_DRIVE_TIME_POLYGON(c.address, 'US', 45, 'minute', 'auto')
      INTO isochrone
      FROM customers c
      JOIN customer_order_status o
        ON o.customer_id = c.customer_id
      WHERE c.name = p_customer_name
        AND o.order_number = p_order_number
      FETCH FIRST 1 ROW ONLY;

      -- Step 2a: Find all stores whose locations fall inside that drive-time polygon.
      -- This counts how many candidate pickup stores are within the reachable area.
      SELECT COUNT(*)
      INTO out_nstores
      FROM stores s
      WHERE SDO_ANYINTERACT(SDO_GEOMETRY(s.longitude, s.latitude), isochrone) = 'TRUE';

      -- Step 2b: Rank the stores inside the polygon by actual route drive time.
      -- The nearest store is selected by ordering first by calculated travel time,
      -- then by store name as a deterministic tie-breaker.
      SELECT store_name, drive_time
      INTO out_store_name, out_drive_time
      FROM (
        SELECT s.store_name,
               ROUND(
                 SDO_GCDR.ELOC_ROUTE_TIME(
                   'fastest',
                   'minute',
                   c.geometry.sdo_point.X,
                   c.geometry.sdo_point.Y,
                   s.longitude,
                   s.latitude,
                   'auto'
                 ),
                 0
               ) AS drive_time
        FROM stores s
        JOIN customers c
          ON c.name = p_customer_name
        WHERE SDO_ANYINTERACT(SDO_GEOMETRY(s.longitude, s.latitude), isochrone) = 'TRUE'
        ORDER BY drive_time, s.store_name
      )
      WHERE ROWNUM = 1;

      RETURN 'There are ' || out_nstores ||
             ' stores nearby. The closest is ' || out_store_name ||
             ' with a drive time of ' || out_drive_time || ' minutes';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 'No stores within drive time';
      WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
    END;
    /
    </copy>
    ```

5. Test the function for a specific customer and order.

    ```
    <copy>
    SELECT find_local_pickup('David Johnson', 3928);
    </copy>
    ```
**Result:**
    ```
    There are 2 stores nearby. The closest is Peoria Riverfront Center with a drive time of 6 minutes
    ```

## Task 4: Create Tools to Update the Database and Find a Local Pickup

Tools are what allow agents to perform tasks in the "real" world. You'll create two tools that a task will use: one updates the order status, and one finds a local pickup option. Each tool is identified by a unique name and includes attributes that define its purpose, instruction logic, and metadata. You'll verify the tools by querying a corresponding view.

1. Create Update\_Order\_Status\_Tool.

    ```
    <copy>
    
    BEGIN DBMS_CLOUD_AI_AGENT.drop_tool('Update_Order_Status_Tool');
    EXCEPTION WHEN OTHERS THEN NULL; END;
    /
    BEGIN
        DBMS_CLOUD_AI_AGENT.CREATE_TOOL(
            tool_name => 'Update_Order_Status_Tool',
            attributes => '{"instruction": "This tool updates the database to reflect return status change. Use the customer name and order number the customer already stated in this conversation. Only ask the customer if either one is missing or ambiguous. Never use a name or order number the customer did not provide.",
                            "function" : "update_customer_order_status"}',
            description => 'Tool for updating customer order status in database table.'
        );
    END;
    </copy>
    ```

2. Create Find\_Local\_Pickup\_Tool. This tool uses the `find_local_pickup` function. The `tool_inputs` attribute describes each function parameter, so the agent knows which values to pass.

    ```
    <copy>
    
    BEGIN
      DBMS_CLOUD_AI_AGENT.drop_tool('Find_Local_Pickup_Tool');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
    /

    BEGIN
      DBMS_CLOUD_AI_AGENT.CREATE_TOOL(
        tool_name => 'Find_Local_Pickup_Tool',
        description => 'Tool for finding the best local pickup option for a customer based on shortest drive time.',
        attributes => '{"instruction": "Never ask for customer number. This tool looks for local pickup options for a customer order. ' ||
                                      'Always ask for customer name and order number before using this tool. ' ||
                                      'The tool returns the number of nearby locations, the store with the shortest drive time, and the drive time to that store.",
                        "function" : "find_local_pickup",
                        "tool_inputs": [{"name":"p_customer_name",
                                        "mandatory": true,
                                        "description" : "customer name, for example David Johnson"},
                                        {"name":"p_order_number",
                                        "mandatory": true,
                                        "description" : "order number, for example 3928"} ]}'
      );
    END;
    /
    </copy>
    ```

3. Verify the Update\_Order\_Status\_Tool and Find\_Local\_Pickup\_Tool by querying `USER_AI_AGENT_TOOLS` view.

    ```
    <copy>
    select * from USER_AI_AGENT_TOOLS
    order by created desc
    </copy>
    ```

## Task 5: Create a Task to Handle the Product Return

We use a task to specify the instructions for performing actions using tools. You'll define a task that your Select AI agent will perform. Each task has a unique name and a set of attributes that specify  its behavior when planning and performing the task. In this scenario, you'll describe the interaction with the customer and how to respond in various cases.

Customers rarely give information in a fixed order. The instruction tells the agent to collect the customer name, order number, and return reason in any order, and to never ask for something the customer already provided. For any replacement, the agent calls Find\_Local\_Pickup\_Tool and reports only the store and drive time that the tool returns.

Create Handle\_Product\_Return\_Task.

  ```
  <copy>
  
  BEGIN DBMS_CLOUD_AI_AGENT.drop_task('Handle_Product_Return_Task');
  EXCEPTION WHEN OTHERS THEN NULL; END;
  /
  BEGIN
    DBMS_CLOUD_AI_AGENT.create_task(
      task_name  => 'Handle_Product_Return_Task',
      attributes => '{"instruction": "Process a product return request from a customer: {query}. ' ||
        'Before every reply, review the ENTIRE conversation history and extract: customer name, order number, return reason ' ||
        '(no longer needed, arrived too late, box broken, defective) and, only when the reason is arrived too late, box broken or defective, refund-or-replacement preference. Never ask about refund or replacement when the reason is no longer needed. ' ||
        'Information may arrive in any order. Never ask for something the customer already provided. Only use a customer name or order number that the customer explicitly typed in this conversation. Never guess, infer, or take a name or order number from tool results, the database, or earlier unrelated conversations. If the customer has not stated their name, ask for it. ' ||
        'If several items are missing, ask for all of them in ONE question. ' ||
        'Always use the human tool to ask the customer questions; do not give a final answer while information is still missing. ' ||
        'Once name, order number and reason are known, act: ' ||
        '1. No longer needed: tell the customer to ship it back at their expense and set status return_shipment_pending with Update_Order_Status_Tool. ' ||
        '2. Arrived too late: if refund, set refund_completed and confirm; if replacement, set replacement_initiated. ' ||
        '3. Defective or box broken: if refund, set refund_completed; if replacement, set replacement_initiated. ' ||
        '4. For any replacement, call Find_Local_Pickup_Tool with the same name and order number and report only the store and drive time it returns. ' ||
        '5. After the action is completed, ask if you can help with anything else. If the customer starts another return, treat it as a brand-new return: ask for the name, order number and reason for that item in one question, even if they were mentioned before, and never reuse details from a previous return. ' ||
        'Only give a final answer when the customer says they need nothing else.",
        "tools": ["Update_Order_Status_Tool", "Find_Local_Pickup_Tool"]}'
    );
  END;
  /
  </copy>
  ```


<if type="sandbox">
## Task 6: Check OCI Credentials
Because you are using an Oracle LiveLabs-provided sandbox environment, a credential named **AI_CREDENTIAL** is already defined for you.
</if>


<if type="tenancy">
## Task 6: Create OCI Credentials
Before you create and use an AI profile, you must create your OCI credential. In this task you will gather the required parameters for OCI Gen AI credential and create a credential that will be used in the next task to create an AI profile.

Follow these steps to create your OCI credentials:
1. User OCID

   a. Go to the OCI Console.

   b. Open the profile menu (top right, click your profile icon) -> **User Settings**.

   c. Copy the OCID shown there.
   ![Copy your user OCID](./images/copy-your-ocid.png =70%x*)

2. Tenancy OCID

   a. From the same user menu -> go to **Tenancy**.
   ![Click Tenancy from profile menu](./images/click-tenancy.png =70%x*)

   b. Copy the **OCID** shown there.
   ![Copy the tenancy OCID](./images/copy-tenancy-ocid.png =70%x*)

3. Fingerprint

   This comes from the public key you upload when you create an API key.

   a. Navigate to **User Settings** -> **Tokens and Keys** -> click **Add API key**.

   ![Click User settings in your profile](./images/profile-user-settings.png =70%x*)
   ![Navigate to Tokens and Keys tab](./images/tokens-and-keys-tab.png)
   
   b. After creating and uploading a public key, OCI generates a fingerprint for it. Copy that value. 
   If you already have a public key on your system, skip the first step below:

   b1. If you are creating a new API key, select **Generate API key pair** and click **Download public key** and **Download private key** to download both public and private keys to your local system.
   ![Create your API key pair](./images/gen-api-key-pair.png)
  
   b2. Come back to the Add API key screen and select **Choose public key file** and upload the file from your system or drag and drop the file. Once your file is uploaded, the **Add** button is enabled. Click **Add**.
   ![Choose public key file](./images/upload-public-key.png)

   b3. OCI generates a fingerprint and a Configuration file preview is displayed. Copy the fingerprint value and click **Close**.

   You can also copy the fingerprint value after closing the Configuration file preview screen under the API Keys section in the console.


4. Private Key

   This is the private key file you generated locally (when you created the API key pair).

   Usually named `oci_api_key.pem`.

   Open it in a text editor and copy the entire contents, including:
     ```
     -----BEGIN PRIVATE KEY-----
     ...key content...
     -----END PRIVATE KEY-----
     ```
5. Create an OCI Gen AI credential.

    ```
    <copy>
    
    begin
      DBMS_CLOUD.drop_credential(credential_name => 'AI_CREDENTIAL');
      EXCEPTION WHEN OTHERS THEN NULL; END;
    end;
    /
    BEGIN
      DBMS_CLOUD.create_credential(
        credential_name => 'AI_CREDENTIAL',
        user_ocid       => '<ocid>',
        tenancy_ocid    => '<tenancy ocid>',
        private_key     => '<private key>',
        fingerprint     => '<fingerprint>'
      );
    END;
    </copy>
    ```

6. Let's confirm that the OCI Credential named **AI_CREDENTIAL** is available for the user.  You should see it listed when you run the following query.
</if>

<if type="sandbox">
1. Let's confirm that the OCI Credential named **AI_CREDENTIAL** is available for the user.  You should see it listed when you run the following query.
</if>

    ```
    <copy>
    SELECT OWNER, CREDENTIAL_NAME, ENABLED FROM ALL_CREDENTIALS WHERE CREDENTIAL_NAME='AI_CREDENTIAL';
    </copy>
    ```



## Task 7: Create an AI Profile
You'll create an AI profile with LLM of your choice, to use in the next step to create an agent. In this task, you are using xAi's GROK Reasoning model with the OCI Gen AI credential.

```
<copy>

BEGIN
  BEGIN DBMS_CLOUD_AI.drop_profile(profile_name => 'OCI_GENAI_GROK'); 
  EXCEPTION WHEN OTHERS THEN NULL; END;

  DBMS_CLOUD_AI.create_profile(
      profile_name => 'OCI_GENAI_GROK',
      attributes   => '{
          "provider": "oci",
          "credential_name": "AI_CREDENTIAL",
          "model": "xai.grok-4.20-reasoning",
          "embedding_model": "cohere.embed-v4.0"
      }',
      description  => 'Supports the Select AI Sales Return Agent scenario.'
  ); 
END;
</copy>
```

## Task 8: Define Customer Agent

You'll create an agent, which specifies the LLM to use through an AI profile and the role the agent plays.

Create the Customer\_Return\_Agent.

```
<copy>

BEGIN DBMS_CLOUD_AI_AGENT.drop_agent('Customer_Return_Agent');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  DBMS_CLOUD_AI_AGENT.create_agent(
    agent_name => 'Customer_Return_Agent',
    attributes => '{"profile_name": "OCI_GENAI_GROK",
                    "role": "You are an experienced customer return agent who deals with customers return requests."}');
END;
</copy>
```

## Task 9: Create the Agent Team

You'll define an agent team that uses the agent and tasks specified above. You specify agent-task pairs for defining a sequential workflow. If you have multiple agents or multiple tasks, these are specified within the JSON list. The same Agent can be specified multiple times with their associated tasks. In this scenario it is a single agent and task pair.

The `long_term_memory_length` attribute sets how many summaries of earlier task runs the team includes as context when a new run starts. The default is 30. Here, you set it to 1, the lowest accepted value. This keeps details from earlier, unrelated returns, such as another customer's name, out of a new conversation.

Create the Return\_Agency\_Team.

```
<copy>

BEGIN DBMS_CLOUD_AI_AGENT.drop_team('Return_Agency_Team');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN                                                                 
  DBMS_CLOUD_AI_AGENT.create_team(  
    team_name  => 'Return_Agency_Team',                                                            
    attributes => '{"agents": [{"name" : "Customer_Return_Agent", 
                                "task" : "Handle_Product_Return_Task"}],
                    "process": "sequential",
                    "long_term_memory_length": 1}');                                                                 
END;

</copy>
```

## Task 10: Interact with the Return Agency Agent

You can start interacting with the Select AI agent team by using natural language prompt on the SQL command line. To do so, you must set the agent team for the current stateful session. Then, prefix your prompt with `select ai agent`. You'll interact with the agent team using natural language. Behind the scenes, the ReAct agent pattern is used by Select AI Agent to get needed information from you, the customer, engage the LLM, call the needed tools, and respond.
Let's test it:

1. Set the agent team in the current session.

    ```
    <copy>
    
    BEGIN DBMS_CLOUD_AI_AGENT.clear_team();
    EXCEPTION WHEN OTHERS THEN NULL; END;
    / 
    EXEC DBMS_CLOUD_AI_AGENT.set_team(team_name  => 'Return_Agency_Team');
    </copy>
    ```

2. Interact with the Return Agency in a series of natural language prompts.

    ```
    <copy>
    select ai agent I want to return a smartphone case;
    </copy>
    ```
**Result:**
    ```
    RESPONSE
    To process your return request for the smartphone case, please provide your name, order number, and reason for the return (no longer needed, arrived too late, box broken, or defective) in one response.
    ```

    ```
    <copy>
    select ai agent the item is defective
    </copy>
    ```
**Result:**
    ```
    RESPONSE
    To process your defective smartphone case return, please provide your name and order number.
    ```

    ```
    <copy>
    select ai agent I will need a replacement
    </copy>
    ```
**Result:**
    ```
    RESPONSE
    To process your defective smartphone case return with replacement, please provide your name and order number.
    ```

    ```
    <copy>
    select ai agent I''m Bob Martinez and my order number is 7820
    </copy>
    ```
**Result:**
    ```
    RESPONSE
    Thank you, Bob Martinez. Your order 7820 has been updated for a replacement due to the defective item. The closest store for pickup is Folsom Mall, a 9-minute drive. Can I help with anything else?
    ```

    Because the customer asked for a replacement, the agent called Find\_Local\_Pickup\_Tool and reported the closest store and its drive time.

    >**Note:** LLM responses vary from run to run. Your wording may differ from the results shown here.

To continue, you may try these prompts in the given sequence. The agent treats the smartphone stand as a new return, so it asks for the name, order number, and reason again. Because the reason is _no longer needed_, the agent does not offer a refund or replacement:

a. _select ai agent Yes, I''d like to return a smartphone stand;_

b. _select ai agent I no longer need it_

c. _select ai agent I''m Bob Martinez with order number is 7820_

d. _select ai agent No, I''m all set. Thanks_


## Task 11: Use `DBMS_CLOUD_AI_AGENT.RUN_TEAM`

The RUN_TEAM procedure enables you to use your agent team from PL/SQL - as opposed to the SQL command line. This procedure is mainly to enable you to build your own agentic applications where you may need greater control over individual conversations. First, you'll create Select AI conversation and then use the `DBMS_CLOUD_AI_AGENT.RUN_TEAM` function to run the agent team and interact with the Return Agency team. Creating a conversation helps the agent team to keep track of the customer conversation context and history.

1. Create Select AI conversation.

    ```
    <copy>
    
    CREATE OR REPLACE PACKAGE my_globals IS
      l_team_cov_id varchar2(4000);
    END my_globals;
    /
    -- Create conversation
    DECLARE
      l_team_cov_id varchar2(4000);
    BEGIN
      l_team_cov_id := DBMS_CLOUD_AI.create_conversation();
      my_globals.l_team_cov_id := l_team_cov_id;
      DBMS_OUTPUT.PUT_LINE('Created conversation with ID: ' || my_globals.l_team_cov_id);
    END;
    </copy>
    ```
2. Call the `DBMS_CLOUD_AI_AGENT.RUN_TEAM` function. Interact with the Return Agency team in a series of prompts provided within the function. This function holds your conversation ID so that Select AI does not lose the context and prompt history.
    ```
    <copy>
    
    DECLARE
      v_response VARCHAR2(4000);
    BEGIN
      v_response :=  DBMS_CLOUD_AI_AGENT.RUN_TEAM(
        team_name   => 'Return_Agency_Team',
        user_prompt => 'I want to return a smartphone case',
        params      => '{"conversation_id": "' || my_globals.l_team_cov_id || '"}'
      );
      DBMS_OUTPUT.PUT_LINE(v_response);
    END;
    </copy>
    ```
**Result:**
    ```
    To process your return for the smartphone case, please provide your name, order number, and reason for return (no longer needed, arrived too late, box broken, or defective) in one response.
    ```

    ```
    <copy>
    
    DECLARE
      v_response VARCHAR2(4000);
    BEGIN
      v_response :=  DBMS_CLOUD_AI_AGENT.RUN_TEAM(
        team_name   => 'Return_Agency_Team',
        user_prompt => 'the item is defective',
        params      => '{"conversation_id": "' || my_globals.l_team_cov_id || '"}'
      );
      DBMS_OUTPUT.PUT_LINE(v_response);
    END;
    </copy>
    ```
**Result:**
    ```
    Please provide your name and order number to proceed with the defective smartphone case return.
    ```

    ```
    <copy>
    
    DECLARE
      v_response VARCHAR2(4000);
    BEGIN
      v_response :=  DBMS_CLOUD_AI_AGENT.RUN_TEAM(
        team_name   => 'Return_Agency_Team',
        user_prompt => 'I''d like a replacement',
        params      => '{"conversation_id": "' || my_globals.l_team_cov_id || '"}'
      );
      DBMS_OUTPUT.PUT_LINE(v_response);
    END;
    </copy>
    ```
**Result:**
    ```
    Please provide your name and order number to proceed with the defective smartphone case return and replacement.
    ```

    ```
    <copy>
    
    DECLARE
      v_response VARCHAR2(4000);
    BEGIN
      v_response :=  DBMS_CLOUD_AI_AGENT.RUN_TEAM(
        team_name    => 'Return_Agency_Team',
        user_prompt => 'I''m Bob Martinez and my order number is 7820',
        params      => '{"conversation_id": "' || my_globals.l_team_cov_id || '"}'
      );
      DBMS_OUTPUT.PUT_LINE(v_response);
    END;
    </copy>
    ```
**Result:**
    ```
    Thank you, Bob Martinez. Your order 7820 has been updated for a replacement due to the defective item. The closest pickup location is Folsom Mall, a 9-minute drive. Can I help with anything else?
    ```

    ```
    <copy>
    
    DECLARE
      v_response VARCHAR2(4000);
    BEGIN
      v_response :=  DBMS_CLOUD_AI_AGENT.RUN_TEAM(
        team_name => 'Return_Agency_Team',
        user_prompt => 'No, thank you',
        params => '{"conversation_id": "' || my_globals.l_team_cov_id || '"}'
      );
      DBMS_OUTPUT.PUT_LINE(v_response);
    END;
    </copy>
    ```
**Result:**
    ```
    Thank you for your return request. Have a great day!
    ```

You may now proceed to the next lab.

## Learn More

* [Blog: Geocoding API in Oracle Autonomous Database Serverless](https://blogs.oracle.com/database/new-in-database-geocoder-for-autonomous-database-shared)
* [Spatial Developer's Guide](https://docs.oracle.com/en/database/oracle/oracle-database/26/spatl/sdo_gcdr-package-geocoding.html)
* [OML Notebooks](https://docs.oracle.com/en/database/oracle/machine-learning/oml-notebooks/index.html)
* [DBMS\_CLOUD\_AI\_AGENT Package](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/dbms-cloud-ai-agent-package.html)
* [Using Oracle Autonomous AI Database Serverless](https://docs.oracle.com/en/cloud/paas/autonomous-database/adbsa/index.html)
* [Example of creating an OCI Gen AI Select AI Profile](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/select-ai-examples.html#GUID-BD10A668-42A6-4B44-BC77-FE5E5592DE27)
* [How to help AI models generate better natural language queries](https://blogs.oracle.com/datawarehousing/post/how-to-help-ai-models-generate-better-natural-language-queries-in-autonomous-database)

## Acknowledgements

* **Author:** Ramu Murakami Gutierrez, Senior Product Manager
* **Contributor:** Marcos Arancibia, Lead Principal Product Manager; David Lapp, Product Management Architect
* **Last Updated By/Date:** Marcos Arancibia, October 2026

Copyright (c) 2026 Oracle Corporation.

Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.3
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
A copy of the license is included in the section entitled [GNU Free Documentation License](https://oracle-livelabs.github.io/adb/shared/adb-15-minutes/introduction/files/gnu-free-documentation-license.txt)