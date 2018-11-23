# Head Pose Detection using Intel® Distribution of  OpenVINO™ toolkit
### Lab Overview
We have done face, age and gender Detection in our previous labs. Now, we will detect Head pose for the identified faces.    
We build upon our Face, Age and Gender detection code from previous labs to add Head Pose detection code in this module.

**Class diagram for Head Pose Detection**

![](images/Headpose_class.png)

### Tasks TODO for Head Pose Detection:
-	Select CPU as plugin device for head pose detection inference.
-	Load pre-trained data model for head pose detection.
-	Once face detection result is available, submit inference request for head pose detection
-	Mark the identified faces inside rectangle and draw Raw ,Yaw and Pitch axis.
-	Observe head pose detection in addition to face, age and gender.

![](images/Headpose_flowchart.png)

### Define a head pose class
Here, we will define a class that includes the declaration of data member and member functions that will be used for head pose detection using OpenVINO™ toolkit.
- Replace **#TODO: Define class for head pose detection** with the following code snippet.

```
struct HeadPoseDetection {

	ExecutableNetwork net;
	InferencePlugin * plugin;
	InferRequest::Ptr request;
	std::string & commandLineFlag = FLAGS_m_hp;
	std::string topoName = "Head Pose";
	const int maxBatch = FLAGS_n_hp;
	std::string input;
	std::string outputAngleR = "angle_r_fc";
	std::string outputAngleP = "angle_p_fc";
	std::string outputAngleY = "angle_y_fc";
	int enquedFaces = 0;
	cv::Mat cameraMatrix;
	double yaw;
	double pitch;
	double roll;
	void submitRequest();
	void wait();
	void matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor = 1.0, int batchIndex = 0);
	void load(InferenceEngine::InferencePlugin & plg);
	void enqueue(const cv::Mat &face);
	struct Results {
		float angle_r;
		float angle_p;
		float angle_y;
	};
	Results operator[] (int idx) const {
		Blob::Ptr  angleR = request->GetBlob(outputAngleR);
		Blob::Ptr  angleP = request->GetBlob(outputAngleP);
		Blob::Ptr  angleY = request->GetBlob(outputAngleY);

		return{ angleR->buffer().as<float*>()[idx],
			angleP->buffer().as<float*>()[idx],
			angleY->buffer().as<float*>()[idx] };
	}

	CNNNetwork read();

	void buildCameraMatrix(int cx, int cy, float focalLength);
	void drawAxes(cv::Mat& frame, cv::Point3f cpoint, Results headPose, float scale);
};

```

### Setup the blob for head pose detection
This is used to process the original image from live feed and populate blob data detection data from captured Mat buffer.
- Replace **#TODO: HeadPose-Blob Detection** with the following code snippet.

```
void HeadPoseDetection::matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor, int batchIndex) {
	SizeVector blobSize = blob.get()->dims();
	const size_t width = blobSize[0];
	const size_t height = blobSize[1];
	const size_t channels = blobSize[2];

	float* blob_data = blob->buffer().as<float*>();

	cv::Mat resized_image(orig_image);
	if (width != orig_image.size().width || height != orig_image.size().height) {
		cv::resize(orig_image, resized_image, cv::Size(width, height));
	}

	int batchOffset = batchIndex * width * height * channels;

	for (size_t c = 0; c < channels; c++) {
		for (size_t h = 0; h < height; h++) {
			for (size_t w = 0; w < width; w++) {
				blob_data[batchOffset + c * width * height + h * width + w] =
					resized_image.at<cv::Vec3b>(h, w)[c] * scaleFactor;
			}
		}
	}
}
```

### Parse the CNNNetwork from given IR
This method is used to parse the intermediate representation format of CNNNetwork models (that is .bin and .xml files).
-  Replace **#TODO: HeadPose-Parse CNNNetworks** with the following code snippet.

```
CNNNetwork HeadPoseDetection::read() {
	//slog::info << "Loading network files for Head Pose detection " << slog::endl;
	CNNNetReader netReader;
	/** Read network model **/
	netReader.ReadNetwork(FLAGS_m_hp);
	/** Set batch size to maximum currently set to one provided from command line **/
	netReader.getNetwork().setBatchSize(maxBatch);
	netReader.getNetwork().setBatchSize(maxBatch);
	//slog::info << "Batch size is sey to  " << netReader.getNetwork().getBatchSize() << " for Head Pose Network" << slog::endl;
	/** Extract model name and load it's weights **/
	std::string binFileName = fileNameNoExt(FLAGS_m_hp) + ".bin";
	netReader.ReadWeights(binFileName);
	/** Age Gender network should have one input two outputs **/
		InputsDataMap inputInfo(netReader.getNetwork().getInputsInfo());
	if (inputInfo.size() != 1) {
		throw std::logic_error("Head Pose topology should have only one input");
	}
	InputInfo::Ptr& inputInfoFirst = inputInfo.begin()->second;
	inputInfoFirst->setPrecision(Precision::FP32);
	inputInfoFirst->getInputData()->setLayout(Layout::NCHW);
	input = inputInfo.begin()->first;
	// ---------------------------Check outputs ------------------------------------------------------

	OutputsDataMap outputInfo(netReader.getNetwork().getOutputsInfo());
	if (outputInfo.size() != 3) {
		throw std::logic_error("Head Pose network should have 3 outputs");
	}
	std::map<std::string, bool> layerNames = {
		{ outputAngleR, false },
		{ outputAngleP, false },
		{ outputAngleY, false }
	};

	for (auto && output : outputInfo) {
		CNNLayerPtr layer = output.second->getCreatorLayer().lock();
		if (layerNames.find(layer->name) == layerNames.end()) {
			throw std::logic_error("Head Pose network output layer unknown: " + layer->name + ", should be " +
				outputAngleR + " or " + outputAngleP + " or " + outputAngleY);
		}
		if (layer->type != "FullyConnected") {
			throw std::logic_error("Head Pose network output layer (" + layer->name + ") has invalid type: " +
				layer->type + ", should be FullyConnected");
		}
		auto fc = dynamic_cast<FullyConnectedLayer*>(layer.get());
		if (fc->_out_num != 1) {
			throw std::logic_error("Head Pose network output layer (" + layer->name + ") has invalid out-size=" +
				std::to_string(fc->_out_num) + ", should be 1");
		}
		layerNames[layer->name] = true;
	}
	return netReader.getNetwork();
}
```
### Build camera matrix for head pose Detection
Here, this method takes camera frame rows and columns as input and builds the matrix.
-  Replace **#TODO: HeadPoseDetection buildCameraMatrix** with the following code snippet.
```
void HeadPoseDetection::buildCameraMatrix(int cx, int cy, float focalLength) {
	if (!cameraMatrix.empty()) return;
	cameraMatrix = cv::Mat::zeros(3, 3, CV_32F);
	cameraMatrix.at<float>(0) = focalLength;
	cameraMatrix.at<float>(2) = static_cast<float>(cx);
	cameraMatrix.at<float>(4) = focalLength;
	cameraMatrix.at<float>(5) = static_cast<float>(cy);
	cameraMatrix.at<float>(8) = 1;
}
```

### Drawing Raw, Yaw and Pitch axis
This is used to process the headpose angle of identified face and draw Raw, Yaw and Pitch axis on the console.
- Replace **#TODO: HeadPoseDetection-drawAxes** with the following code snippet.
```
void HeadPoseDetection::drawAxes(cv::Mat& frame, cv::Point3f cpoint, Results headPose, float scale) {
	yaw = headPose.angle_y;
	pitch = headPose.angle_p;
	roll = headPose.angle_r;

	pitch *= CV_PI / 180.0;
	yaw *= CV_PI / 180.0;
	roll *= CV_PI / 180.0;

	cv::Matx33f        Rx(1, 0, 0,
		0, cos(pitch), -sin(pitch),
		0, sin(pitch), cos(pitch));
	cv::Matx33f Ry(cos(yaw), 0, -sin(yaw),
		0, 1, 0,
		sin(yaw), 0, cos(yaw));
	cv::Matx33f Rz(cos(roll), -sin(roll), 0,
		sin(roll), cos(roll), 0,
		0, 0, 1);

	auto r = cv::Mat(Rz*Ry*Rx);
	buildCameraMatrix(frame.cols / 2, frame.rows / 2, 950.0);

	cv::Mat xAxis(3, 1, CV_32F), yAxis(3, 1, CV_32F), zAxis(3, 1, CV_32F), zAxis1(3, 1, CV_32F);

	xAxis.at<float>(0) = 1 * scale;
	xAxis.at<float>(1) = 0;
	xAxis.at<float>(2) = 0;

	yAxis.at<float>(0) = 0;
	yAxis.at<float>(1) = -1 * scale;
	yAxis.at<float>(2) = 0;

	zAxis.at<float>(0) = 0;
	zAxis.at<float>(1) = 0;
	zAxis.at<float>(2) = -1 * scale;

	zAxis1.at<float>(0) = 0;
	zAxis1.at<float>(1) = 0;
	zAxis1.at<float>(2) = 1 * scale;

	cv::Mat o(3, 1, CV_32F, cv::Scalar(0));
	o.at<float>(2) = cameraMatrix.at<float>(0);

	xAxis = r * xAxis + o;
	yAxis = r * yAxis + o;
	zAxis = r * zAxis + o;
	zAxis1 = r * zAxis1 + o;

	cv::Point p1, p2;

	p2.x = static_cast<int>((xAxis.at<float>(0) / xAxis.at<float>(2) * cameraMatrix.at<float>(0)) + cpoint.x);
	p2.y = static_cast<int>((xAxis.at<float>(1) / xAxis.at<float>(2) * cameraMatrix.at<float>(4)) + cpoint.y);
	cv::line(frame, cv::Point(cpoint.x, cpoint.y), p2, cv::Scalar(0, 0, 255), 2);

	p2.x = static_cast<int>((yAxis.at<float>(0) / yAxis.at<float>(2) * cameraMatrix.at<float>(0)) + cpoint.x);
	p2.y = static_cast<int>((yAxis.at<float>(1) / yAxis.at<float>(2) * cameraMatrix.at<float>(4)) + cpoint.y);
	cv::line(frame, cv::Point(cpoint.x, cpoint.y), p2, cv::Scalar(0, 255, 0), 2);

	p1.x = static_cast<int>((zAxis1.at<float>(0) / zAxis1.at<float>(2) * cameraMatrix.at<float>(0)) + cpoint.x);
	p1.y = static_cast<int>((zAxis1.at<float>(1) / zAxis1.at<float>(2) * cameraMatrix.at<float>(4)) + cpoint.y);

	p2.x = static_cast<int>((zAxis.at<float>(0) / zAxis.at<float>(2) * cameraMatrix.at<float>(0)) + cpoint.x);
	p2.y = static_cast<int>((zAxis.at<float>(1) / zAxis.at<float>(2) * cameraMatrix.at<float>(4)) + cpoint.y);
	cv::line(frame, p1, p2, cv::Scalar(255, 0, 0), 2);
	cv::circle(frame, p2, 3, cv::Scalar(255, 0, 0), 2);
}
```


### Load CNNNetwork for head pose detection
Here, we will define a method that will be used for loading the CNNNetworks that will be used for head pose detection.
- Replace **#TODO: HeadPose-LoadNetwork** with the following code snippet.

```
void HeadPoseDetection::load(InferenceEngine::InferencePlugin & plg) {

	net = plg.LoadNetwork(this->read(), {});
	plugin = &plg;

}
```

### Populate the inference request
This method is used populate the inference request and push the frames in to a queue for further processing.
- Replace **#TODO: HeadPose-populate Inference Request** with the following code.

```
void HeadPoseDetection::enqueue(const cv::Mat &face) {

	if (!request) {
		request = net.CreateInferRequestPtr();
	}

	Blob::Ptr  inputBlob = request->GetBlob(input);

	matU8ToBlob(face, inputBlob, 1.0f, enquedFaces);

	enquedFaces++;
}
```

### Submit inference request and wait for result
Here we will define methods to submit inference request and wait for inference result.
- Replace **#TODO: HeadPose-submit Inference Request and wait** with the following code snippets.

```
void HeadPoseDetection::submitRequest() {
	if (!enquedFaces) return;
	request->StartAsync();
	enquedFaces = 0;
}

void HeadPoseDetection::wait() {
	if (!request) return;
	request->Wait(IInferRequest::WaitMode::RESULT_READY);
}

```

### Include CPU as plugin device
Till now, we have defined all the required methods required for head pose detection. Now we will extend our Face detection application with head pose detection.
We will use CPU as plugin device for inferencing head pose
- Replace **#TODO: head pose detection 1** with the following lines of code

```
plugin = PluginDispatcher({ "../../../lib/intel64", "" }).getPluginByDevice("CPU");
	pluginsForDevices["CPU"] = plugin;
```

### Load pre-trained optimized model for head pose Inferencing
We need CPU as plugin device for inferencing HeadPose and load pre-retained model for head pose detection on CPU
- Replace **#TODO: HeadPose Detection 2** with the following lines of code

```
FLAGS_m_hp = "/opt/intel/computer_vision_sdk/deployment_tools/intel_models/head-pose-estimation-adas-0001/FP32/head-pose-estimation-adas-0001.xml";
	HeadPoseDetection HeadPose;
	HeadPose.load(pluginsForDevices["CPU"]);

```

### Submit Inference Request
- Replace **#TODO: HeadPose Detection 3** with the following lines of code

```
//Submit Inference Request for HeadPose detection and wait for result
	 HeadPose.submitRequest();
	 HeadPose.wait();

```

### Use identified face for head pose detection
Clip the identified Faces and send inference request for identifying head pose
- Replace **#TODO: HeadPose Detection 4** with the following line of code

```
HeadPose.enqueue(face1);

```

### Calculate attentivityindex
Here attentivityindex will be calculated on the basis of Yaw angle.
- Replace **#TODO: HeadPose Detection 5** with the following lines of code

```
if (index < HeadPose.maxBatch) {

			cv::Point3f center(rect.x + rect.width / 2, rect.y + rect.height / 2, 0);
			HeadPose.drawAxes(frame, center, HeadPose[index], 50);
			if (HeadPose.yaw > -0.4 && HeadPose.yaw < -0.001)
			{
				attentivityindex++;

			}
		}

 ```

### The Final Solution
Keep the TODOs as it is. We will re-use this program during Cloud Integration.     
For complete solution click on following link [face_AgeGender_headpose_detection.cpp](./solutions/Headposedetection.md)

### Build the Solution and Observe the Output
- Go to ***~/Desktop/Retail/OpenVINO/samples/build***  directory
- Do  make by following commands   
- Make sure environment variables set when you are doing in fresh terminal.      

```
# make
```

- Executable will be generated at ***~/Desktop/Retail/OpenVINO/samples/build/intel64/Release*** directory.
- Run the application by using below command. Make sure camera is connected to the device.

```
# ./interactive_face_detection_sample
 ```


- On successful execution, Face, Age  Gender and HeadPose will get detected.

### Lesson Learnt
In addition to face, age and gender - added head pose Detection using  OpenVINO™ toolkit.

## Next Lab
[Analyze face, age, gender, head pose data on Cloud](./Analyse_face_data_on_cloud.md)
