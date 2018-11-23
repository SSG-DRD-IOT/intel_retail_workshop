# Analyze face, age, gender detection data on Cloud
### Lab Overview
We have done face, age, gender and headpose detection in our previous labs. Also, we have successfully counted number of faces so far.

In this Lab, we will publish this data to local cloud for analysis.
### Tasks to do in this lab
- Declare a device id that will be used for publishing the data to cloud
- Integrate a python script for publishing the data to cloud
- Publish the number of faces after showing the face count
- Login to cloud and view charts showing the face count,Male count and female count

### Declare the device id
- Replace **#TODO: Cloud Integration 1** with the following line of code.

```
std::string deviceId="1234";
```

### Publish face count, male count and female count to cloud
We counted the number of faces,number of males and number of females successfully. Now, we will publish it to cloud for analysis.	

**Note:** We are not publishing video stream or pictures of the screen. We are only publishing the number of faces. For publishing the data to cloud we will be integrating a python script.
- The following content should be present in a python script called as “cloud.py” and should be available in ***Desktop > Retail > OpenVINO***
- If file is not present, create a "cloud.py" file and add the following code snippet into that file.

```
import requests
import sys
import json
import time

id = sys.argv[1]
facecount = int(sys.argv[2])
malecount = int(sys.argv[3])
femalecount = int(sys.argv[4])
attentivityindex= int(sys.argv[5])

count = {"facecount":facecount, "malecount":malecount, "femalecount":femalecount, "attentivityindex":attentivityindex, "timestamp":time.strftime('%H:%M:%S')}
query = 'id=' + str(id) + '&value=' + str(facecount) +'&malecount=' + str(malecount) +'&femalecount=' + str(femalecount);
with open('/home/intel/Desktop/Retail/OpenVINO/AttentivityData.json', 'w') as file:
     file.write(json.dumps(count))

resp = requests.get('http://<ip_address>:9002/analytics/face?'+ query);
if resp.status_code != 201:
    print("Unable to submit the data")
else:
    print("Data Submitted for analysis")
```
### Integrate cloud module
- Replace #TODO: Cloud Integration 2 with below code snippet

```
//Submit data to cloud when there is change in face count
  if (framecounter == 10)
  {
    prevFaceCount = curFaceCount;
    //slog::info << framecounter << slog::endl;
    //Integrate python module to submit data to cloud
    std::string cmd = "python /home/intel/Desktop/Retail/OpenVINO/cloud.py " + id + " " + std::to_string(curFaceCount) + " " + std::to_string(malecount) + " " + std::to_string(femalecount) + " " + std::to_string(attentivityindex);
    int systemRet = std::system(cmd.c_str());
    if (systemRet == -1)
      slog::info << "System fails : " << slog::endl;
    slog::info << "Number of faces in the frame are : " << curFaceCount << slog::endl;
    slog::info << "male count is " << malecount << slog::endl;
    slog::info << "female count is " << femalecount << slog::endl;
    slog::info << "Attentivity index is " << attentivityindex << slog::endl;
    slog::info << "__________________________________________" << slog::endl;
    framecounter = 0;
  }
```
### Build the Solution and Observe the Output
- Go to ***~/Desktop/Retail/OpenVINO/samples/build***  directory
- Do  make by following commands
- Make sure environment variables set when you are doing in fresh terminal.

```
# source /opt/intel/computer_vision_sdk/bin/setupvars.sh
# make
```

- Executable will be generated at ***~/Desktop/Retail/OpenVINO/samples/build/intel64/Release*** directory.
- Run the application by using below command. Make sure camera is connected to the device.

```
# ./interactive_face_detection_sample
 ```

- On successful execution, face, age and gender will get detected file.json will be created at ***~/Desktop/Retail/OpenVINO***

### Visualizing your Data on the Cloud
Real time visualization of number of people, age and gender on local cloud
- Run local server by using below command

```
cd ~/Desktop/Retail/OpenVINO/lab-8.0-solution-cloud-analytics-retail-workshop
node server.js
 ```
- Go to http://localhost:9002
- Example : 127.0.0.1:9002
- Enter your device id
- Click the plot
- See the real time face count on cloud

![](images/cloudAnalysis.png)

###  Final Solution
For complete solution click on following link [analyse_face_data_on_cloud.cpp](./solutions/cloudanalysis.md) which includes Face, Age and Gender detection using OpenVINO™ toolkit.

### Lesson Learnt
Interfacing OpenVINO™ toolkit with cloud and visualizing data on cloud.

##  

[Video Analytics Home](./README.md)
