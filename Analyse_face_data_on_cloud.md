# Analyze Face Data on Cloud
### Lab Overview
We have done Face, Age and Gender Detection in our previous modules. Also, we have successfully counted number of faces so far.

In this Lab, we will publish this data to local cloud for analysis.
### Tasks to do in this lab
- Declare a device id that will be used for publishing the data to cloud
- Integrate a python script for publishing the data to cloud
- Publish the number of faces after showing the face count
- Login to cloud and view charts showing the number of faces

### Declare the Device Id
- Replace #TODO: Cloud Integration 1
- Paste the following line and replace the device id “1234” with your device id written on your computer.

```
std::string deviceId="1234";
```

### Publish Number of Faces to Cloud
We counted the number of faces successfully. Now, we will publish it to cloud for analysis.       

**Note:** We are not publishing video stream or pictures of the screen. We are only publishing the number of faces. For publishing the data to cloud we will be integrating a python script.
- The following content should be present in a python script called as “cloud.py” and should be available in ***Desktop > Retail > OpenVINO***
- If file is not present, create a "cloud.py" file and add the following code snippet into that file.

```
#import requests
import sys
import json

id = sys.argv[1]
facecount = sys.argv[2]
malecount = sys.argv[3]
femalecount = sys.argv[4]

count = {"facecount":facecount, "malecount":malecount, "femalecount":femalecount}

print(id);
print(facecount);
query = 'id' + '&value=' + str(facecount);
print(query);

with open('/home/intel/Desktop/Retail/OpenVINO/file.json', 'w') as file:
     file.write(json.dumps(count))

resp = requests.get('http://10.138.77.101:9002/analytics/face?'+ query);

if resp.status_code != 201:
  print("Unable to submit the data")
else:
  print("Data Submitted for analysis")
 ```
### Integrate cloud module
- Replace #TODO: Cloud Integration 2 with below code snippet

```
  //Submit data to cloud when there is change in face count
  if (curFaceCount != prevFaceCount && curFaceCount < faceCountThreshold)
		{
			prevFaceCount = curFaceCount;
			//Integrate python module to submit data to cloud
			std::string cmd = "python /home/intel/Desktop/Retail/OpenVINO/cloud.py  " + id + " " + std::to_string(curFaceCount) + " " + std::to_string(malecount) + " " + std::to_string(femalecount) ;
			int systemRet = std::system(cmd.c_str());
			if (systemRet == -1)
			slog::info << "System fails : " <<slog::endl;
			slog::info << "Number of faces in the frame are : " << curFaceCount << slog::endl;
			slog::info << "male count is " << malecount << slog::endl;
			slog::info << "female count is " << femalecount << slog::endl;
		}

```
### Build the Solution and Observe the Output
- Go to ***~/Desktop/Retail/OpenVINO/samples/build***  directory
- Do  make by following commands
- Make sure environment variables set when you are doing in fresh terminal.

```
# source /opt/intel/computer_vision_sdk_2018.1.265/in/setupvars.sh
# make
```

- Executable will be generated at ***~/Desktop/Retail/OpenVINO/samples/build/intel64/Release*** directory.
- Run the application by using below command. Make sure camera is connected to the device.

```
# ./interactive_face_detection_sample
 ```

- On successful execution, Face, Age and Gender will get detected file.json will be created at ***~/Desktop/Retail/OpenVINO***

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
For complete solution click on following link [analyse_face_data_on_cloud.cpp](./solutions/cloudanalysis.md) which includes Face, Age and Gender detection using OpenVINO™.
### Lesson Learnt
Interfacing OpenVINO™ toolkit with cloud and visualizing data on cloud.
