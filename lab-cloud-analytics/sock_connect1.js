var json;
var myDeviceId = "";
var color = Chart.helpers.color;

var datatemplate = {
    label: '',
    backgroundColor: color(window.chartColors.red).alpha(0.5).rgbString(),
    borderColor: window.chartColors.red,
    borderWidth: 1,
    data: []
};

var chart; // global variuable for chart
var dataTopics = new Array();


 var socket = io.connect('http://192.168.11.19:9002');
 socket.on('connect', function(data) {
    alert("Connected");
 socket.on('plotdata', function(data) {
	 try {
     json = JSON.parse(data);
   onMessageArrived(json);

    	} catch(e) {

	}
    });
});




  //what is done when a message arrives from the broker
  function onMessageArrived(message) {
     console.log("Index" + barChartData.labels.indexOf(message.id));
    //check if it is a new topic, if not add it to the array
    if (barChartData.labels.indexOf(message.id) < 0){
      console.log("New Data Topic", message.id)
      barChartData.labels.push(message.id); //add new topic to array
      var dataset = datatemplate;
      var y = barChartData.labels.indexOf(message.id); //get the index no
      dataset.label = message.id;
      dataset.data[0] = parseInt(message.value);
      barChartData.datasets.push(dataset);
  }
  else {
    var y = barChartData.labels.indexOf(message.id); //get the index no
    barChartData.datasets[y].data[0] = parseInt(barChartData.datasets[y].data[0]) + parseInt(message.value);
  }
  console.log(barChartData);
  window.myBar.update();
}
