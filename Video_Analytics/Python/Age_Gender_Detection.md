# Age and Gender Detection using the Intel® Distribution of OpenVINO™ toolkit
### Lab Overview
We have done Face Detection in our previous module. Now, we identify Age and Gender for the identified faces.    
We  build upon our Face Detection code and add Age, Gender identification code in this module.



### Tasks TODO for Age and Gender Detection:
- Defining the command line arguments required for Age and gender detection.
-	Load pre-trained data model for Age and Gender detection.
- Initializing the parameters to process the output.
- Resetting the parameters for each frame.
-	Once Face Detection result is available, submit inference request for Age and Gender Detection
-	Mark the identified faces inside rectangle and put text on it for Age and Gender.
-	Observe Age and Gender Detection in addition to face.

![](images/AgeGender_flowchart.PNG)


### 1. Parsing command line arguments

We define the command line arguments required for age and gender detection.
- Replace **#TODO Age_Gender command line arguments**
- Paste the following lines

```python
parser.add_argument("-m_ag", "--ag_model", help="Path to an .xml file with a trained model.", default=None, type=str)
parser.add_argument("-d_ag", "--device_ag",
                    help="Target device for Age/Gender Recognition network (CPU, GPU, FPGA, or MYRIAD). The demo will look for a suitable plugin for a specified device. (CPU by default)", default="CPU",
                    type=str)
#TODO Head_Pose command line arguments
  ```  
### 2. Load Pre-trained Optimized Model for Age and Gender Inferencing

In previous step, CPU is selected as plugin device. Now, load pre-trained optimized model for age and gender detection inferencing on CPU.
- Replace **#TODO Age_Gender_Detection 1**
- Paste the following lines

```python
# age and gender   
   if args.model and args.ag_model:
      age_enabled =True
      #log.info("Loading network files for Age/Gender Recognition")
      plugin,ag_net = load_model("Age/Gender Recognition",args.ag_model,args.device_ag.upper(),args.plugin_dir,1,2,args.cpu_extension)
      age_input_blob=next(iter(ag_net.inputs))
      age_out_blob=next(iter(ag_net.outputs))
      age_exec_net=plugin.load(network=ag_net, num_requests=2)
      ag_n, ag_c, ag_h, ag_w = ag_net.inputs[input_blob].shape
      del ag_net

  #TODO Head_Pose_Detection 2
```

### 3. Initialize the parameters
Here initialize the parameters which are required to process the output.
- Replace **#TODO Age_Gender_Detection 2**
- Paste the following lines

```python
curFaceCount = 0
prevFaceCount = 0
index = 0
malecount = 0
femalecount = 0
attentivityindex = 0
```

### 4. Resetting the parameters for each frame
The initialized parameters which are required to process the output are reset to zero.

- Replace **#TODO Age_Gender_Detection 3**
- Paste the following lines

```python
curFaceCount = 0
malecount=0
femalecount = 0
attentivityindex=0
```

### 5. Process Face detection Inference Results
At this stage face detection Inference results will be available for further processing. Here, identified face will be clipped off and will be used for identifying age and gender in next request for inferencing.

- Replace **#TODO Age_Gender_Detection 4**
- Paste the following lines

```python
#Age and Gender
age_inf_time=0
if age_enabled:
    age_inf_start = time.time()
    clipped_face = cv2.resize(clippedRect, (ag_w, ag_h))
    clipped_face = clipped_face.transpose((2, 0, 1))  # Change data layout from HWC to CHW
    clipped_face = clipped_face.reshape((ag_n, ag_c, ag_h, ag_w))
    ag_res = age_exec_net.start_async(request_id=0,inputs={'data': clipped_face})
    # Face count
    curFaceCount+=1
    if age_exec_net.requests[cur_request_id].wait(-1) == 0:
        age_inf_end = time.time()
        age_inf_time=age_inf_end - age_inf_start
#TODO Head_Pose_Detection 3          

```

### 6. Process Age and Gender detection Results for display
Now we got result for Face, Age and Gender detection. We can customize the output and display this on the screen
- Replace **#TODO Age_Gender_Detection 5**
- Paste the following lines

```python
if age_enabled:
    age = int((age_exec_net.requests[cur_request_id].outputs['age_conv3'][0][0][0][0])*100)
    if(((age_exec_net.requests[cur_request_id].outputs['prob'][0][0][0][0])) > 0.5):
        gender = 'F'
        femalecount+=1

    else:
        gender = 'M'
        malecount+=1
    cv2.putText(frame, str(gender) + ','+str(age), (xmin, ymin - 7), cv2.FONT_HERSHEY_COMPLEX, 0.6, (10,10,200), 1)
    cv2.rectangle(frame, (xmin, ymin), (xmax, ymax), (255, 10, 10), 2)

```

### The Final Solution
Keep the TODOs as it is. We will re-use this program during Cloud Integration.     
For complete solution click on following link [age_gender_detection](./solutions/agegenderdetection.md)


- Open command prompt and type this command

```
python3 main.py -i cam -m /opt/intel/computer_vision_sdk/deployment_tools/intel_models/face-detection-adas-0001/FP32/face-detection-adas-0001.xml -m_ag /opt/intel/computer_vision_sdk/deployment_tools/intel_models/age-gender-recognition-retail-0013/FP32/age-gender-recognition-retail-0013.xml -l /opt/intel/computer_vision_sdk/inference_engine/samples/build/intel64/Release/lib/libcpu_extension.so

 ```
- On successful execution, Face, Age and Gender will get detected.

### Lesson Learnt
In addition to Face, Age and Gender Detection using the Intel® Distribution of OpenVINO™ toolkit.

## Next Lab
[HeadPose Detection using the Intel® Distribution of OpenVINO™ toolkit](./Head_Pose_Detection.md)
