const { Client } = require('pg')
const serverless = require('serverless-http')

const pg_client = new Client({
  user: 'postgres',
  host: 'localhost',
  database: 'AirmeeTest',
  password: 'admin',
  port: 5432,
})
pg_client.connect();
module.exports= pg_client
