
-- View for next week's delivery dates and corresponding delivery window start and stop time against each store
CREATE OR REPLACE VIEW admin.vw_delivery AS
SELECT vs.id,
       vs.store_name,
       to_date(concat(extract(YEAR
                              FROM CURRENT_DATE), (date_part('week', CURRENT_DATE)+1)), 'IYYYIW')+sap.day_of_week-1 AS week_date,
       sap.day_of_week,
       to_char(concat(sap.delivery_start_window_hours, ':', '00')::TIME, 'hh24:mi') AS earliest_delivery_time,
       to_char(concat(sap.delivery_stop_window_hours, ':', '00')::TIME, 'hh24:mi') AS latest_by_delivery_time
FROM admin.vendor_stores vs
INNER JOIN service.schedules_and_prices sap ON vs.id= sap.retailer_id;

-- View for next week's pickup dates and corresponding pickup window start and stop time against each store
CREATE OR REPLACE VIEW admin.vw_pickup AS
SELECT vs.id,
       vs.store_name,
       to_date(concat(extract(YEAR
                              FROM CURRENT_DATE), (date_part('week', CURRENT_DATE)+1)), 'IYYYIW')+vswh.day_of_week-1 AS week_date,
       vswh.day_of_week,
       to_char(concat(vswh.working_start_window_hours, ':', '00')::TIME, 'hh24:mi') AS earliest_pickup_time,
       to_char(concat(vswh.working_stop_window_hours, ':', '00')::TIME, 'hh24:mi') AS latest_by_pickup_time
FROM admin.vendor_stores vs
INNER JOIN admin.vendor_store_work_hours vswh ON vs.id= vswh.retailer_id;

-- View for consolidated next week's pickup and delivery dates (unix timestamp in milliseconds and human readable interval) against each store
CREATE OR REPLACE VIEW admin.vw_next_week_available_schedules AS
SELECT CASE
           WHEN pi.store_name IS NULL THEN de.store_name
           ELSE pi.store_name
       END AS store_name,
       CASE
           WHEN pi.week_date IS NULL THEN EXTRACT (epoch
                                                   FROM'1900-01-01'::TIMESTAMP)
           ELSE extract(epoch
                        FROM concat(pi.week_date, ' ', earliest_pickup_time)::TIMESTAMP)
       END AS earliest_pickup_datetime,
       CASE
           WHEN pi.week_date IS NULL THEN EXTRACT (epoch
                                                   FROM'1900-01-01'::TIMESTAMP)
           ELSE extract(epoch
                        FROM concat(pi.week_date, ' ', latest_by_pickup_time)::TIMESTAMP)
       END AS latest_pickup_datetime,
       concat(to_char(pi.week_date, 'dd Mon'), ' ', earliest_pickup_time, '-', latest_by_pickup_time) AS human_readable_pickup_interval,
       extract(epoch
               FROM concat(de.week_date, ' ', earliest_delivery_time)::TIMESTAMP) AS earliest_delivery_datetime,
       extract(epoch
               FROM concat(de.week_date, ' ', latest_by_delivery_time)::TIMESTAMP) AS latest_delivery_datetime,
       concat(to_char(de.week_date, 'dd Mon'), ' ', earliest_delivery_time, '-', latest_by_delivery_time) AS human_readable_delivery_interval
FROM admin.vw_delivery de
LEFT JOIN admin.vw_pickup pi ON de.id = pi.id
AND de.week_date = pi.week_date
ORDER BY de.id;

-- Query for use in API to present next week schedules
SELECT store_name,
       earliest_pickup_datetime,
       latest_pickup_datetime,
       human_readable_pickup_interval,
       earliest_delivery_datetime,
       latest_delivery_datetime,
       human_readable_delivery_interval
FROM admin.vw_next_week_available_schedules;

-- Query to present next day delivery for Gothenburg area
SELECT store_name,
       earliest_pickup_datetime,
       latest_pickup_datetime,
       human_readable_pickup_interval,
       case when area_name = 'Gothenburg' then earliest_delivery_datetime + (24*60*60) else earliest_delivery_datetime end as earliest_delivery_datetime,
       case when area_name = 'Gothenburg' then latest_delivery_datetime + (24*60*60) else latest_delivery_datetime end as latest_delivery_datetime,
       case when area_name = 'Gothenburg' then to_char(to_timestamp(earliest_delivery_datetime+(24*60*60)), 'DD Mon')||substring(human_readable_delivery_interval,7,17) else human_readable_delivery_interval end as human_readable_delivery_interval,
	   area_name
FROM admin.vw_next_week_available_schedules
inner join service.areas 
on area_name='Gothenburg'
and store_name='Large store';

-- Create table for holiday work hours for retailer
CREATE TABLE IF NOT EXISTS admin.holiday_vendor_store_work_hours
(retailer_id uuid references admin.vendor_stores(id), 
holiday_date varchar(6), -- 'dd Mon' format  
working_start_window_hours integer, 
working_start_window_minutes integer, 
working_stop_window_hours integer, 
working_stop_window_minutes integer
);

-- Add data to holiday work hours (08:00 to 12:00) for retailer
INSERT INTO admin.holiday_vendor_store_work_hours(retailer_id, holiday_date, 
working_start_window_hours, working_start_window_minutes, working_stop_window_hours, working_stop_window_minutes)
SELECT id, '24 Dec', 8, 0, 12, 0
FROM admin.vendor_stores
WHERE id||'24 Dec' NOT IN (SELECT retailer_id||holiday_date from admin.holiday_vendor_store_work_hours); 

INSERT INTO admin.holiday_vendor_store_work_hours(retailer_id, holiday_date, 
working_start_window_hours, working_start_window_minutes, working_stop_window_hours, working_stop_window_minutes)
SELECT id, '25 Dec', 8, 0, 12, 0
FROM admin.vendor_stores
WHERE id||'25 Dec' NOT IN (SELECT retailer_id||holiday_date from admin.holiday_vendor_store_work_hours); 

INSERT INTO admin.holiday_vendor_store_work_hours(retailer_id, holiday_date, 
working_start_window_hours, working_start_window_minutes, working_stop_window_hours, working_stop_window_minutes)
SELECT id, '31 Dec', 8, 0, 12, 0
FROM admin.vendor_stores
WHERE id||'31 Dec' NOT IN (SELECT retailer_id||holiday_date from admin.holiday_vendor_store_work_hours); 

INSERT INTO admin.holiday_vendor_store_work_hours(retailer_id, holiday_date, 
working_start_window_hours, working_start_window_minutes, working_stop_window_hours, working_stop_window_minutes)
SELECT id, '01 Jan', 8, 0, 12, 0
FROM admin.vendor_stores
WHERE id||'01 Jan' NOT IN (SELECT retailer_id||holiday_date from admin.holiday_vendor_store_work_hours); 

-- Create table for holiday delivery hours for Airmee
CREATE TABLE IF NOT EXISTS service.holiday_schedules_and_prices
(retailer_id uuid references admin.vendor_stores(id), 
holiday_date varchar(6), -- 'dd Mon' format 
delivery_start_window_hours integer, 
delivery_start_window_minutes integer, 
delivery_stop_window_hours integer, 
delivery_stop_window_minutes integer,
price double precision default 59.0,
price_currency text default 'SEK');

-- Add data to holiday delivery hours (14:00 to 17:00) for Airmee
INSERT INTO service.holiday_schedules_and_prices(retailer_id, holiday_date, 
delivery_start_window_hours, delivery_start_window_minutes, delivery_stop_window_hours, delivery_stop_window_minutes)
SELECT id, '24 Dec', 14, 0, 17, 0
FROM admin.vendor_stores
WHERE id||'24 Dec' NOT IN (SELECT retailer_id||holiday_date from service.holiday_schedules_and_prices);

INSERT INTO service.holiday_schedules_and_prices(retailer_id, holiday_date, 
delivery_start_window_hours, delivery_start_window_minutes, delivery_stop_window_hours, delivery_stop_window_minutes)
SELECT id, '25 Dec', 14, 0, 17, 0
FROM admin.vendor_stores
WHERE id||'25 Dec' NOT IN (SELECT retailer_id||holiday_date from service.holiday_schedules_and_prices);

INSERT INTO service.holiday_schedules_and_prices(retailer_id, holiday_date, 
delivery_start_window_hours, delivery_start_window_minutes, delivery_stop_window_hours, delivery_stop_window_minutes)
SELECT id, '31 Dec', 14, 0, 17, 0
FROM admin.vendor_stores
WHERE id||'31 Dec' NOT IN (SELECT retailer_id||holiday_date from service.holiday_schedules_and_prices);

INSERT INTO service.holiday_schedules_and_prices(retailer_id, holiday_date, 
delivery_start_window_hours, delivery_start_window_minutes, delivery_stop_window_hours, delivery_stop_window_minutes)
SELECT id, '01 Jan', 14, 0, 17, 0
FROM admin.vendor_stores
WHERE id||'01 Jan' NOT IN (SELECT retailer_id||holiday_date from service.holiday_schedules_and_prices);

