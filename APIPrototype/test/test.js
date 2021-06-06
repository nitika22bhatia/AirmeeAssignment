//During the test the env variable is set to test
// This we can use if we separate Test database.For this exercise I am using actual database.
//process.env.NODE_ENV = 'test'; 

//Require the dev-dependencies
let chai = require('chai');
let chaiHttp = require('chai-http');
let server = require('../backend-srvc');
const dbConn = require('../config/dbConfig')
let should = chai.should();
const { Client } = require('pg')


chai.use(chaiHttp);

describe('Access to DB', function(){
    describe('#success', function(){
         it(' return success', function(done){
            const pg_client = new Client({
                user: 'postgres',
                host: 'localhost',
                database: 'AirmeeTest',
                password: 'admin',
                port: 5432,
              })
              pg_client.connect(done);
         });
     })
 });
 describe('getAllData', () => {
    /*
      * Test the /GET route **/
      
      describe('/', () => {
          it('it should GET all the available schedules for next week', (done) => {
            chai.request(server)
                .get('/getAllData')
                .end((err, res) => {
                      res.should.have.status(200);
                      res.body.should.be.a('object');
                      res.body.should.have.property('data').that.includes.all.keys(['rows']);
                  done();
                });
          });
      });
    
    }); 
    