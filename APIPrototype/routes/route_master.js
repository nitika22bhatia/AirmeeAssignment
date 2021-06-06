const controller           = require("../controller/schedule.controller");
var express = require('express');
var router = express.Router();
router.get("/getAllData",controller.getAllData);
module.exports = router ;