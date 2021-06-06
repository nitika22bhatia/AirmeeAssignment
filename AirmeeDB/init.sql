
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS citext;

CREATE SCHEMA IF NOT EXISTS admin; 
CREATE SCHEMA IF NOT EXISTS service; 
CREATE SCHEMA IF NOT EXISTS schedules_and_prices; 

-- This table stores a simplified version for this demo of the details we store for retailer 
CREATE TABLE IF NOT EXISTS admin.vendor_stores
(id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(), 
store_name text, 
store_email citext);

CREATE TABLE IF NOT EXISTS admin.vendor_store_work_hours
(retailer_id uuid references admin.vendor_stores(id), 
day_of_week integer, 
working_start_window_hours integer, 
working_start_window_minutes integer, 
working_stop_window_hours integer, 
working_stop_window_minutes integer
);

INSERT INTO admin.vendor_store_work_hours(retailer_id, day_of_week, 
working_start_window_hours, working_start_window_minutes, working_stop_window_hours, working_stop_window_minutes)
SELECT id, generate_series(1,5), 8, 0, 15, 0
FROM admin.vendor_stores
WHERE id NOT IN (SELECT retailer_id from admin.vendor_store_work_hours);

INSERT INTO admin.vendor_stores(store_name, store_email)
SELECT * FROM (
	SELECT 'Large store' as store_name, 'large_store@airmee.com' as store_email
	UNION ALL 
	SELECT 'Medium store', 'medium_store@airmee.com'
	UNION ALL 
	SELECT 'Small store', 'small_store@airmee.com'
) insertion_table 
WHERE store_name not in (select store_name from admin.vendor_stores)
AND store_email not in (select store_email from admin.vendor_stores);


-- This table stores a simplified version for this demo of the details we store for each delivery area / zone 
CREATE TABLE IF NOT EXISTS service.areas
(id uuid PRIMARY KEY default uuid_generate_v1mc(), 
area_name text, 
area_geometry text /*This would be of type geometry for PostGIS*/);

insert into service.areas(area_name, area_geometry)
SELECT * FROM (
	SELECT 'Stockholm' as area_name, 'random polygon' as area_geometry
	UNION ALL 
	SELECT 'Gothenburg', 'random polygon2'
	UNION ALL 
	SELECT 'London', 'random polygon3'
) insertion_table 
WHERE area_name not in (select area_name from service.areas)
AND area_geometry not in (select area_geometry from service.areas);

-- This table stores the delivery schedules and prices
CREATE TABLE IF NOT EXISTS service.schedules_and_prices
(retailer_id uuid references admin.vendor_stores(id), 
day_of_week integer, 
delivery_start_window_hours integer, 
delivery_start_window_minutes integer, 
delivery_stop_window_hours integer, 
delivery_stop_window_minutes integer,
price double precision default 59.0,
price_currency text default 'SEK');

-- we deliver for all stores between 17 and 22 
INSERT INTO service.schedules_and_prices(retailer_id, day_of_week, 
delivery_start_window_hours, delivery_start_window_minutes, delivery_stop_window_hours, delivery_stop_window_minutes)
SELECT id, generate_series(0,6), 17, 0, 22, 0
FROM admin.vendor_stores
WHERE id NOT IN (SELECT retailer_id from service.schedules_and_prices);