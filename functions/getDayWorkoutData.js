const functions = require("firebase-functions");
var mysql = require("./mysql.js");

module.exports = function(e) {
  e.getDayWorkoutData = functions.https.onCall((data, context) => {
    return new Promise((resolve, reject) => {
      var sql = "SELECT * FROM day_workouts DESC";
      console.log(mysql);
      mysql.query(sql, [], (err, result) => {
        if (err) {
          console.log("error ", err);
          reject(err);
        }
        console.log("return from database");
        console.log(JSON.stringify(result));
        resolve(JSON.stringify(result));
      });
    });
  });
};
