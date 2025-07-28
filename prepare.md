# Table types

- Permanent (up to 90 days: time travel)
    - Persist until dropped
    - Designed for data that requires the highest level of data protection and recovery
    - Default table type
- Temporary (0 or 1 days: time travel)
    - Persist and tier to a session (think signle user)
    - Used for transitory data (fro example ETL|ELT)
- Transient (0 or 1 days: time travel)
    - Persist until dropped
    - Multiple user
    - Used fir data that needs to persist, but does not need the same level of data retention as a permanent table
- External
    - Persist until removed
    - Snowflake "over" an external data lake
    - Data accessed via an external stage
    - Read-only

```sql
use role accountadmin;

use warehouse COMPUTE_WH;

create or replace database mydb;
create or replace schema mydb.myschema;

create or replace table permanent_table
(
id int,
name string
);

alter table permanent_table set data_retention_time_in_days = 90;

create or replace transient table transient_table
(
id int,
name string
);

create or replace temporary table temporary_table
(id int,
name string);

alter table temporary_table set data_retention_time_in_days = 3;

show tables;
```

# View types

- Standart view
    - Default view type
    - Named definition of query--SELECT statement
    - Executes as executing role
    - Underlying DDL available to any role with access to the view
- Secure view
    - Definition and details only visible to authorized users
    - Executes as owning role
    - Snowflake query optimizer bypassed optimizations user fir regular view
- Materialized view
    - Behaves more like a table
    - Results of underlying query are stored
    - Auto-refreshed
    - Secure Materialized View is also supported

```sql
use role accountadmin;

use warehouse COMPUTE_WH;

use schema mydb.myschema;

-- Create an Employee table
create or replace table employees (
id integer,
name varchar(50),
department varchar(50),
salary integer
);

insert into employees (id, name, department, salary) values
(1, 'Pat Fay','HR',50000),
(2, 'Donald OConnell','IT',75000),
(3, 'Steven King','Sales',60000),
(4, 'Susan Mavris','IT',80000),
(5, 'Jennifer Whalen','Marketing',55000);

select * from employees;

create or replace view it_employee as 
select id,name,salary from employees
where department = 'IT';

select * from it_employee;

create or replace secure view hr_employee as 
select id,name,salary from employees
where department = 'HR';

select * from hr_employee;

create or replace view employee_salaries as
select department, sum(salary) total_salary from employees
group by 1;

create or replace materialized view materialized_employee_salaries as
select department, sum(salary) total_salary from employees
group by 1;

select * from employee_salaries;

select * from materialized_employee_salaries;

show views;
```

# Stage

- Table stage
    - Table stage are linked to specific tables in snowflake
    - when a table is created a corresponding stage is automatically created
    - they are names after the table, and are owned and managed be the table owner
    - this stage os a convenient option if you files need to be accessible to multiple users and need to be copied into single table
- User stage
    - User stage are the default stages  that are automatically created for each user
    - This stage servers as a convenient choise if your files will be only be accessed by a single user but need to copied into multiple tables
    - They are referenced using @~; these stages cannot be altered or dropped
    - Snowflake automatically creates a user stage for you when you create a user
- Named stages
    - Internal
        - Named stages are database object the provides a freates degree of flexibility for data loading
        - Unlike personal user stages or tables specific stages, names stages can be accessd by multiple authorized users and leveraged to load data into serveral tables
    - External
        - Snowflake external stage are stages that store data files in external cloud location
        - They are used to load data from external location into snowflake tables or to export data from snowflake tables to external destinations
        - Currently snowflake supports external stages
            - AWS
            - GCP
            - Azure

```sql
use role accountadmin;

use warehouse compute_wh;

use schema mydb.myschema;

create or replace table customers (
id integer,
name varchar(50),
age integer,
state varchar(50)
);

// access to table stage
list @%customers;

-- access to user stage
list @~;

-- create a named stage
create or replace stage customer_stage;

list @customer_stage;

truncate table customers;

-- load data from stage to table
copy into customers
from @customer_stage
file_format = (type='csv' skip_header=1);

select * from customers;
```

# File Format

- Named object that stores information to parse files during load/unload
    - File type (CSV, Json, etc.)
    - Type-spicific formating options

- Create file format object as part of the stage, or specify within the copy command
- Currently supports the below file format
    - CSV
    - JSON
    - AVRO
    - ORC
    - PARQUET
    - XML

```sql
use role accountadmin;

use warehouse compute_wh;

use schema mydb.myschema;

create or replace table students (
id integer,
name varchar(50),
age integer,
marks integer
);

create or replace stage student_stage;

list @student_stage;

copy into students from @student_stage
file_format = (type='CSV' skip_header=1);

select * from students;

truncate table students;

-- create file format CSV
create file format csv_format
type = 'CSV'
field_delimiter = ','
record_delimiter = '\n'
skip_header = 1;

copy into students from
@student_stage
file_format = (format_name = csv_format);

select * from students;

-- create file format json
create file format json_format
type = 'JSON';

show file formats;
```
# Data Loading Approaches

## Bulk loading Overview (COPY INTO <table> FROM @stage)

- Internal Stage
- External Stage

## Continuous Data Loading

- COPY command (BATCH) (Microbatching)
    - Migration from traditional data source
    - Transaction boundary control
        - begin / start transaction / commit / rollback
    - independently scale compute resources for different ingestion workloads
- Snowpipe (Continuous)
    - Ingestion from modern data sources
    - Continuosly generated data is available for analysis is seconds
    - No scheduling (with auto-ingest)
    - Serverless model with no user-managed virtual warehouse needed

Snowpipe
- Named object contains a COPY statement used by snowppe
    - Source stage for data files
    - Target table
- Loads data into tables continuously from an ingestion queue
- Can be paused/resumed, return status
- Best practice: size files between 10 Mb and 100 Mb (compressed) when staging files for ingest with snowpipe

## Bulk load data from external stage S3

```sql
use role accountadmin;

use warehouse compute_wh;

use schema mydb.myschema;

create or replace table user (
id integer,
name varchar(50),
location varchar(50),
email varchar(50)
);

create or replace storage integration s3_int
type = external_stage
storage_provider = 's3'
enabled = true
storage_aws_role_arn = ''
storage_allowed_location = ('');

desc integration s3_int;

create or replace file format my_csv_fileformat
type = 'csv'
field_delimiter = ','
record_delimiter = '\n'
skip_header = 1;

create or replace stage my_s3_stage
storage_integretaion = s3_int
url = ''
file_format = my_csv_fileformat;

list @my_s3_stage;

copy into user
from @my_s3_stage
file_format = (format_name = my_csv_fileformat);

select * from user;
```

## Continuous load data from external stages S3

```sql
use role accountadmin;

use warehouse compute_wh;

use schema mydb.myschema;

create or replace table event (
event variant
);

create or replace storage integration s3_snowpipe_int
type = external_stage
storage_provider = 's3'
enabled = true
storage_aws_role_arn = ''
storage_allowed_locations = '';

desc integration s3_snowpipe_int;

create or replace file formart my_json_format
type = 'json';

create or replace stage my_s3_snowpipe_stage
storage_integration = s3_snowpipe_int
url = ''
file_format = my_json_format;

list @my_s3_snowpipe_stage;

create or replace pipe s3_pipe auto_ingest = true
as copy into even 
from @my_s3_snowpipe_stage
file_format = (format_name = my_json_format);

select system$pipe_status('s3_pipe');

show pipes;

select * from event;
```

# Snowflake Streams

- Snowflake streams are objects that track all DML operations against the source table
- Under the hood, Snowflake streams add three metadata columns
    - METADATA$ACTION: Indicates the DML operation recorded (INSERT, DELETE, UPDATE)
    - METADATA$ISUPDATE: Tracks UPDATEs as DELETE + INSERT pairs (True or False )
    - METADATA$ROW_ID: Inque row identifier

    To the source table when created
- These additional columns allow the stream to capture information about insert, updates, and deletes without having to store all the table data

Snowflake stream can be created on the following objects:
- Standart tables
- Directory tables
- External tables
- Views

Snowflake streams cannot be created on the following objects:
- Materialized views
- Secure object (like secure views, secure UDFs)

## Stream types

Snowflake offers three flavors of streams to match different needs for capturing data changes:
- Standart streams: As its suggests, this type tracks all modifications made to the source table including insert, updates, deletes. Is you need full data capture capability, standard Snowflake streams are a way to go.
- Append-only streams: These types of Snowflake streams strictly record new rows added to the table-so just INSERTS. Update and delete operations (including table truncates) are not recorded. Append-only streams are great when you need to see new data as it arrives.
- Insert-only streams: Insert-only Snowflake streams which are supported on external tables only. As the name hints, these only track row insterts only; they do not record delete operations that remove rows from an inserted set.

### Standart Stream

```sql
use role accountadmin;

use warehouse compute_wh;

use schema mydb.myschema;

create or replace table source_table1 (
id int,
name varchar,
created_date date
);

insert into source_table1 values
(1, 'Chaos','2023-12-11'),
(2, 'Genuis','2023-12-11');

create or replace stream standart_stream on table source_table1;

select * from source_table1;

select * from standart_stream;

insert into source_table1 values
(3, 'Jhonny','2023-12-11');

select * from source_table1;

select * from standart_stream;

delete from source_table1 where id = 2;

select * from source_table1;

select * from standart_stream;

update source_table1 set name = 'Elon' where id = 1;

select * from source_table1;

select * from standart_stream;

show streams;
```

### Append-only Stream

```sql
create or replace table source_table2 (
id integer,
name varchar,
created_date date
);

insert into source_table2 values
(1, 'Chaos', '2023-12-11'),
(2, 'Genius', '2023-12-11');

create or replace stream append_only_stream on table source_table2 append_only = true;

select * from append_only_stream;

insert into source_table2 values (3, 'Johhny', '2023-01-01');

update source_table2 set name = 'Elon' where id = 1;

select * from source_table2;
```

### Streams using in ETL Processes

```sql
create or replace table target_table2 (
id int,
name varchar,
created_date date
);

select * from append_only_stream;

insert into target_table2
select id,name,created_date from append_only_stream;

select * from target_table2;

insert into source_table2 values (4, 'Rock', '2024-01-01');

select * from source_table2;

select * from append_only_stream;

insert into target_table2
select id,name,created_date from append_only_stream;
```

### Insert-only stream

```sql
create or replace external table ext_table
location = @my_aws_stage
file_format = my_format;

create or replace stream my_ext_stream 
on external table 
ext_table insert_only = true;
```

# Tasks

- Snowflake Tasks let you run SQL on a schedule
- The SQL command can be anything. A single SQL statement, or a call of a stored procedure wich invokes multiple SQL statemenets

Similar to other Snowflake objects, Tasks can be created and managed programatically with SQL. The most common parameters when creating a new task are:
- schedule: when should be task triggered
- warehouse: what compute cluster should be used
- code: the SQL command to run
- condition: a boolean expression that gets evaluated when the Task is triggered. It determines whether the Task will be executed or skipped if the condition is not met

## Tasks types

1. user-managed Snowflake task: you can manage the compute resources for individual tasks by specifying an existing virtual warehouse when creating the task. Make sure you choose a right sized warehouse for the SQL actions defined in task

```sql
create task mytask
warehouse = compute_wh
schedule = '5 minutes'
as 
insert into employees values (employee_squence.nextval.'F_NAME'.'L_NAME'.'101')
```

2. Serverless snowflake task: The serverless compute model for tasks enables you to rely on compute resources managed by snowflake instead of user-managed virtual warehouses

```sql
create task mytask_serverless
user_task_managed_initial_warehouse_size = 'xsmall'
schedule = '5 minutes'
as
insert into emplyees values (employee_squence.nextval.'F_NAME'.'L_NAME'.'101')
```

## Scheduling a tasks

Snowflake Tasks are not event based, instead a task tuns on a schedule. The Snowflake task engine has as CRON and NONCRON variant scheduling mechanisms. You must be familiar with CRON variant's syntax if you are a Linux user

1. NON-CRON notation

```sql
create task mytask
warehouse = compute_wh
schedule = '5 minute'
as
insert into emplyees values (employee_squence.nextval.'F_NAME'.'L_NAME'.'101')
```

2. CRON notation

```sql
create task mytask
warehouse = compute_wh
schedule = 'using cron * 10 * * SUN UTC'
as 
insert into emplyees values (employee_squence.nextval.'F_NAME'.'L_NAME'.'101')
```

```sql
use role accountadmin;

use warehouse compute_wh;

use schema mydb.myschema;

-- without task

create or replace table source_table (
id integer,
name varchar,
created_date date
);

insert into source_table values
(1, 'Chaos', '2024-01-01'),
(2, 'Genius', '2024-01-01');

select * from source_table;

create or replace table target_table (
id integer,
name varchar,
created_date date,
created_day varchar,
created_month varchar,
created_year varchar
);

insert into target_table
select 
a.id,
a.name,
a.created_date,
day(a.created_date) as created_day,
month(a.created_date) as created_month,
year(a.created_date) as created_year
from source_table a
left join target_table b on a.id = b.id
where b.id is null;

select * from target_table;

insert into source_table values 
(3, 'Elan', '2024-05-01');

-- With tasks

create or replace table source_table (
id integer,
name varchar,
created_date date
);

insert into source_table values
(1, 'Chaos', '2024-01-01'),
(2, 'Genius', '2024-01-01');

select * from source_table;

create or replace table target_table (
id integer,
name varchar,
created_date date,
created_day varchar,
created_month varchar,
created_year varchar
);

create or replace task my_task
warehouse = compute_wh
schedule = '1 minute'
as 
insert into target_table
select 
a.id,
a.name,
a.created_date,
day(a.created_date) as created_day,
month(a.created_date) as created_month,
year(a.created_date) as created_year
from source_table a
left join target_table b on a.id = b.id
where b.id is null;

select * from target_table;

show tasks;

alter task my_task resume;
alter task my_task suspend;

insert into source_table values 
(3, 'Elan', '2024-05-01');
```

# Time travel & Fail Sage

## Time travel

### Problem

- User errors
- System errors
- Backup itself is time-consuming task
- Specialized skill and management overhead

Time travel is the solution of problems

- Access historical data at any point within a defined retention period
- UNDO common mistakes
- Protect against accidental or intentional modification, removal, or corruption
    - Fix drops, deletes, edits
- Backup/Resotre from time or ID
- Instantly bring back deleted tables, schemas, and databases
- Restore or duplicate data from keys points in the past:
    - Point-in-time
    - Prior to a specific query ID
- Set retention time at the table, schema, databases, or account level

### Create table with time travel

- Automatic with default retention period (whitch set up on account level):

`create table my_table (c1 int);`

- Customizable retention period

```sql
create table my_table (c1 int)
set data_retention_time_in_days = 90;

alter table my_table (c1 int)
set data_retention_time_in_days = 30;
```

### Querying with time travel

Query clauses is support time travel actions

- AT or BEFORE

```sql
select * from my_table1
at(timestamp => 'Mon, 01 May 2015 16:20:00 -0700'::timestamp);

select * from my_table1
before(statement => '83code asdas');
```

### DML examples

- Cloning Historical Objects

```sql
create table restored_table clone my_table1
at(timestamp => 'Mon, 01 May 2015 16:20:00 -0700'::timestamp);

create database restored_db clone my_db
before(statement => '83code asdas');
```

- Restoring objects

`UNDROP TABLE/SCHEMA/DATABASE`

## How does it work

- Micro-partitions
- Micro-partitions are immutable
- When data is changed, new versions of the micro-partititons are created
- We keep the older version for the specified retention time

## Fail-Safe Overview

- Non-configurable, 7-day retention for historical data after Time travel expiration
- Only accessible by Snowflake personnel
- Admins can view fail-safe use in the Snowflake Web UI under Account > Billing & Usage
- Not supported for temporary or transient tables

```sql
use role accountadmin;

use warehouse compute_wh;

use schema mydb.myschema;

create or replace table drop_table
(
id integer,
name varchar
);

insert into drop_table values 
(1, 'John'),
(2, 'Sam'),
(3, 'Elan'),
(4, 'Mark');

delete from drop_table where id = 4;

select * from drop_table at(offset => -60*5);

show tables;

select * from drop_table at(timestamp => '2025-07-28 00:02:10.875 -0700'::timestamp_tz);

-- from query history
select * from drop_table before(statement => '01bdfc46-0000-94d7-0000-0000b015e07d'); 

create or replace table drop_table_clone as
select * from drop_table before(statement => '01bdfc46-0000-94d7-0000-0000b015e07d');

select * from drop_table_clone;

truncate table drop_table;

insert into drop_table 
select * from drop_table_clone;

drop table drop_table_clone;

select * from drop_table;

-- dropping table, schema, database

drop table drop_table;
select * from drop_table;
undrop table drop_table;

drop schema myschema;
undrop schema myschema;

drop database mydb;
undrop database mydb;

use schema mydb.myschema;

show databases;
```

# Cloning

- Quickly take a "snapshot" of any table, schema, database (clones can be cloned)
- When the clone is created:
    - All micro-partitions in both tables are fully shared
    - Micro-partition storage is owned be the oldest table, clone references them
- No additional storage costs until changes are made to the original or the clone
- Often used to quickly spin up Dev or Test environments
- Effective "backup" option as well

```sql
-- clone the database
create or replace database test_db
clone prod_db;
```

```sql
use role accountadmin;

use warehouse compute_wh;

use schema mydb.myschema;

create or replace database test_mydb
clone mydb;

drop database test_mydb;
```