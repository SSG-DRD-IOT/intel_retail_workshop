var json;
var myDeviceId = "";

 var socket = io.connect(window.location.href);
 socket.on('connect', function(data) {
    alert("Connected");
 socket.on('plotdata', function(data) {
	 try {
      		json = JSON.parse(data);
          json.timestamp = (new Date());
		onMessageArrived(json);
		console.log(json);
    	} catch(e) {

	}

    });
});

var chart; // global variable for chart
var dataTopics = new Array();

  //what is done when a message arrives from the broker
  function onMessageArrived(message) {

    if(myDeviceId != message.id)return;
    updateTable(message);

    //check if it is a new topic, if not add it to the array
    if (dataTopics.indexOf(message.id) < 0){
      console.log("New Data Topic", message.id)
      dataTopics.push(message.id); //add new topic to array

      var y = dataTopics.indexOf(message.id); //get the index no
 console.log(y);
      //create new data series for the chart
      var newseries = {
        id: 0,
        name: 'Face Count',
        data: []
      };

      chart.addSeries(newseries); //add the series
	  var newseries1 = {
        id: 1,
        name: 'Male Count',
        data: []
      };
	 chart.addSeries(newseries1); //add the series
	 var newseries2 = {
        id: 2,
        name: 'Female Count',
        data: []
      };
	   chart.addSeries(newseries2); //add the series
    };
    var oldMessage = null;
    var y = dataTopics.indexOf(message.id);
console.log(y);	//get the index no of the topic from the array
    var myEpoch = new Date().getTime(); //get current epoch time
    var thenum = json.value;
	var maleval = json.malecount;
	var femaleval = json.femalecount;
	//console.log(femaleval)
    if(oldMessage != null && oldMessage.timestamp == message.timestamp)return;
    var plotMqtt = [myEpoch, Number(thenum)]; //create the array
	var plotMqtt1 = [myEpoch, Number(maleval)];
	var plotMqtt2 = [myEpoch, Number(femaleval)];
    if (isNumber(thenum)) { //check if it is a real number and not text
      plot(plotMqtt, 0);	//send it to the plot function
	  plot(plotMqtt1, 1);
	  plot(plotMqtt2, 2);
      oldMessage = message;
    };
  };

  //check if a real number
  function isNumber(n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
  };

  //function that is called once the document has loaded
  function init() {
    console.log ("Data Collected is " + document.getElementById("gatewayInfo").value)
    myDeviceId = document.getElementById("gatewayInfo").value;
    console.log ("Started Init Function")
    document.getElementById("gatewayInfo").disabled = true;
    var gatewayId = document.getElementById("gatewayInfo").value
    console.log ("Device/Gateway Id is ", gatewayId)

    chart.setTitle({text: 'Plotting Realtime data from Gateway ' + gatewayId});

    Highcharts.setOptions({
      global: {
        useUTC: false
      }
    });


  };

  //this adds the plots to the chart
  function plot(point, chartno) {
    
    var series = chart.series[0],
	shift = series.data.length > 200; // shift if the series is
    // longer than 20
    // add the point
	
	console.log(series);
    chart.series[chartno].addPoint(point, true, shift);
	//chart.series[1].addPoint(point, true, shift);
	
	
	
	
	
	
    chart.subtitle

  };


  function updateTable(data) {
    var table = document.getElementById("dataTable");
    var row = table.insertRow(1);
    var cell1 = row.insertCell(0);
    var cell2 = row.insertCell(1);
    var cell3 = row.insertCell(2);
	var cell4 = row.insertCell(3);
	var cell5 = row.insertCell(4);
   cell1.innerHTML = data.id;
   cell2.innerHTML = data.value;
   cell3.innerHTML = data.malecount;
   cell4.innerHTML = data.femalecount;
   cell5.innerHTML = data.timestamp;
  }
