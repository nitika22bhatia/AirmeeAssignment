const express = require('express')
const serverless = require('serverless-http')
const bodyParser = require('body-parser')
const pool = require('./config/dbConfig')
const route_master       = require('./routes/route_master');
const schedule           = require("./controller/schedule.controller");
const app = express()

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))


app.use('/', route_master);

app.use(function (err, req, res, next) {// error handler
    res.status(404).send(err.message)
})

//To run for unit_test (npm test) comment this line
module.exports.handler = serverless(app)

//To run for unit_test uncomment this line
//module.exports= app
