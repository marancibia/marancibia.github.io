-- **Copyright © 2026, Oracle and/or its affiliates.
-- **All rights reserved. Licensed under the Universal Permissive License (UPL), Version 1.0 as shown at https://oss.oracle.com/licenses/upl.


-- **To install the database objects required for the demo. Connect to ADB as ADMIN:**

declare 
    l_uri varchar2(500) := 'https://objectstorage.us-ashburn-1.oraclecloud.com/n/c4u04/b/building_blocks_utilities/o/setup/workshop-setup.sql';
begin
    dbms_cloud_repo.install_sql(
        content => to_clob(dbms_cloud.get_object(object_uri => l_uri))
    );
end;
/

-- Add the ${schema_name} user when provisioning. In update mode, use the
-- existing schema if it exists, or create it when the supplied schema is new.
declare
    l_schema_name varchar2(128) := upper('${schema_name}');
    l_user_count number;
begin
    workshop.write('Begin demo install');
    select count(*)
    into l_user_count
    from dba_users
    where username = l_schema_name;

    if '${adb_operation_mode}' = 'Provision a new Autonomous AI Database with the demo Schema and Applications' or l_user_count = 0 then
        workshop.write('add user ${schema_name}', 1);
        workshop.add_adb_user(l_schema_name,'${user_password}');
    else
        workshop.write('use existing user ${schema_name}', 1);
    end if;
    
    ords_admin.enable_schema (
        p_enabled               => TRUE,
        p_schema                => l_schema_name,
        p_url_mapping_type      => 'BASE_PATH',
        p_auto_rest_auth        => TRUE   
    ); 
    
    -- Allow ${schema_name} to use the resource principal
    dbms_cloud_admin.enable_resource_principal(username  => l_schema_name);

end;
/
