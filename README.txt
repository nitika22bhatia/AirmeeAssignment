API Prototype :

Steps for deployment for Node JS API Protoype:

1)Update Postgres DB name, user, pass in config/dbConfig.js and test/test.js.
2)run 'npm install'
3)Ensure all dependencies are installed : pg,body-parser,serverless,serverless-offline,serverless-http,express,mocha,chai-http,chai
4)run 'npm start' (this will run command 'serverless offline start' to run API in serverless-offline mode)
5)Use postman to test api : http://localhost:3000/dev/getAllData


-backend-srvc.js : handler file for serverless.
-routes/route_master.js : middleware to route http req.
-controller/schedule.controller.js : this file contains logic to retrive data and send response
.config/dbConfig.js : db connection file

To run unit test script :
1) Open file backend-srvc.js and uncomment line 'module.exports= app'  and comment line 'module.exports.handler = serverless(app)'
2) run cmd 'npm test'

Note : All database credentials and NODE_ENV should be saved in env file but for this exercise I used in directly in file.


Database views: 
----

1. View for next week's delivery dates and corresponding delivery window start and stop time against each store.
Name: "admin.vw_delivery"
Tables referred:
	"admin.vendor_stores"
	"service.schedules_and_prices"
Fields:
	"id" - retailer id
	"store_name" - vendor store name
	"week_date" - derived next week date
	"day_of_week" - day of week from schedules and prices table
	"earliest_delivery_time" - earliest delivery time in hh24:mi format
	"latest_by_delivery_time" - latest delivery time in hh24:mi format
----

2. View for next week's pickup dates and corresponding pickup window start and stop time against each store
Name: "admin.vw_pickup"
Tables referred:
	"admin.vendor_stores"
	"admin.vendor_store_work_hours"
Fields:
	"id" - retailer id
	"store_name" - vendor store name
	"week_date" - derived next week date
	"day_of_week" - day of week from schedules and prices table
	"earliest_pickup_time" - earliest pickup time in hh24:mi format
	"latest_by_pickup_time" - latest pickup time in hh24:mi format
----

3. View for consolidated next week's pickup and delivery dates (unix timestamp in milliseconds and human readable interval) against each store
Name: "admin.vw_next_week_available_schedules"
Tables/ Views referred:
	"admin.vw_delivery"
	"admin.vw_pickup"
Fields:
	"store_name" - vendor store name
	"earliest_pickup_datetime" - earliest pickup datetime in unix milliseconds. 
	"latest_pickup_datetime" - latest pickup datetime in unix milliseconds. 
	"human_readable_pickup_interval" - pickup date and time window in format "dd Mon hh24:mi-hh24:mi"
	"earliest_delivery_datetime" - earliest delivery datetime in unix milliseconds. 
	"latest_delivery_datetime" - latest delivery datetime in unix milliseconds. 
	"human_readable_delivery_interval" - delivery date and time window in format "dd Mon hh24:mi-hh24:mi"
Note: Where pickup date is not available/ empty, it is defaulted to corresponding unix millisecods value of '1900-01-01 00:00:00'
