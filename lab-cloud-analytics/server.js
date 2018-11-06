// app.js
var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io')(server);

io.on('connection', function(client) {
    console.log('Client connected...');
    client.on('messages', function(data) {
        console.log(data);
	//try
	{
	console.log(data);
	io.sockets.emit('plotdata',JSON.stringify(data));
	}
	//catch(ex){}
    });

});
app.use(express.static(__dirname + '/'));
app.get('/', function(req, res,next) {
    res.sendFile(__dirname + '/index.html');
});

app.get('/analytics/face',function(req,res)
{
console.log(req.query);
  var data =
	{
	  id:req.query.id,
	  value:parseInt(req.query.value),
	  timestamp: parseInt(req.query.timestamp)
	}
   io.sockets.emit("plotdata", JSON.stringify(data));
   res.status(201).send("Successfully updated");
   res.end();
});

server.listen(9002);
console.log("Server started listening at 9002")
