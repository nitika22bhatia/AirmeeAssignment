const dbConn = require('../config/dbConfig')

module.exports.getAllData = (req, res) => {
    try{
        //const query = 'SELECT * FROM service.areas'
        const query="select store_name,earliest_pickup_datetime,latest_pickup_datetime,human_readable_pickup_interval,earliest_delivery_datetime,latest_delivery_datetime,human_readable_delivery_interval from admin.vw_next_week_available_schedules where store_name='Large store'";
        dbConn.query(query, (err, results, fields) => {
            if (err) {
            const response = { data: null, message: err.message, }
            res.send(response)
            }
            const response = {
            data: results,
            message: 'data received',
            }
            console.log("results---",results)
            res.send(response)
        })
    }
    catch(e)
    {
         console.log(e)
    }
};
