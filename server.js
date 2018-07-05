// Require MQTT and setup the connection to the broker
var mqtt = require('mqtt');
var mqttClient = mqtt.connect('mqtt://192.168.1.1');

// Require the MongoDB libraries and connect to the database
var mongoose = require('mongoose');
mongoose.connect("mongodb://localhost/iotdemo");
var db = mongoose.connection;

// Report database errors to the console
db.on('error', console.error.bind(console, 'connection error:'));

// Log when a connection is established to the MongoDB server
db.once('open', function(callback) {
    console.log("Connection to MongoDB successful");
});

// Import the Database Model Objects
var DataModel = require('intel-commercial-edge-network-database-models').DataModel;
var SensorModel = require('intel-commercial-edge-network-database-models').SensorModel;

// MQTT connection function
mqttClient.on('connect', function() {
    console.log("Connected to MQTT server");

    // Subscribe to the MQTT topics
    mqttClient.subscribe('announcements');
    mqttClient.subscribe('sensors/+/data');
});

// A function that runs when MQTT receives a message
mqttClient.on('message', function(topic, message) {
            var json;
            // Parse the incoming data
            try {
                json = JSON.parse(message);
            } catch (e) {
                console.log(e);
            };

        if (topic.match(/announcements/)) {
            var sensor = new SensorModel(json);
            sensor.save(function(err, sensor) {
                if (err)
                    console.log(err);
                else
                    console.log(topic + ":" + message.toString());
            });
        };

        if (topic.match(/data/)) {
            var value = new DataModel(json);
            value.save(function(err, data) {
                if (err)
                    console.log(err);
                else
                    console.log(topic + ":" + message.toString());
            });
        }
      });
