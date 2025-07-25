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

## Bulk loading Overview

- Internal Stage
- External Stage

## Continuous Data Loading