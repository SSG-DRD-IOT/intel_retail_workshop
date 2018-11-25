# Face Detection using the Intel® Distribution of OpenVINO™ toolkit
### Lab Overview
In our previous Lab, we have successfully run the prebuilt application using the Intel® Distribution of OpenVINO™ toolkit.

In our next three Labs, we will develop a complete interactive face detection application in three phase.
- Face detection
- Age and Gender detection
- Analyze Face, Gender and Age detection data on cloud

For simplicity, we have created a main.cpp, which includes required header files and TODOs that to be replaced.
- TODO is small unit of module for code simplification.
- Replace all TODOs with corresponding code snippets provide.
- keep all other TODOs as it is. We will  use these in our next labs

The main.cpp file is available in below path of your device:
***~/Desktop/Retail/OpenVINO/samples/interactive_face_detection_sample/main.cpp***

In this Lab, we will build a Face Detection application which will detect a face from live camera feed. Here, we will be working with TODOs for Face Detection only, keep all other TODOs as it is. We will  use these in our next labs.

**Class diagram for face detection**

![](images/faceDetection_class.png)

### This lab will be laid out as follows:
-	Include the required header files.
- Define class and required methods for our application development.
-	Capture video frames using OpenCV API.
-	Load in inference engine plugins.
-	Load in pre-trained optimized Face Detection model.
-	Request for inference on GPU.
-	With the inference result, draw a rectangle marking the face.

![](images/faceDetection_flowchart.png)

### Include Required Headers
First, we will include required header files for inferencing with the Intel® Distribution of OpenVINO™ toolkit.
- Replace **#TODO: Face Detection 1** with the following lines of code

```cpp
#include <inference_engine.hpp>
#include "interactive_face_detection.hpp"
#include "mkldnn/mkldnn_extension_ptr.hpp"
#include <opencv2/opencv.hpp>
```

### Define A FaceDetection Class
Next, we will define a class that includes the declaration of data member and member functions that will be used for face detection using the Intel® Distribution of OpenVINO™ toolkit.
- Replace **#TODO: Define class for Face Detection** with the following lines of code

```cpp
struct FaceDetectionClass  {

	ExecutableNetwork net;
	InferenceEngine::InferencePlugin * plugin;
	InferRequest::Ptr request;
	std::string & commandLineFlag = FLAGS_Face_Model;
	std::string topoName = "Face Detection";
	const int maxBatch = 1;
	ExecutableNetwork*  operator ->() {
		return &net;
	}
	std::string input;
	std::string output;
	int maxProposalCount;
	int objectSize;
	int enquedFrames = 0;
	float width = 0;
	float height = 0;
	bool resultsFetched = false;
	std::vector<std::string> labels;

	struct Result {
		int label;
		float confidence;
		cv::Rect location;
	};
  std::vector<Result> results;
 void submitRequest() ;
 void wait() ;
 void matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor = 1.0, int batchIndex = 0);
 void enqueue(const cv::Mat &frame);
 InferenceEngine::CNNNetwork read();
 void load(InferenceEngine::InferencePlugin & plg);
 void fetchResults();
};
```
### Setup the Blob for Face detection
This is used to process the original image from live feed and populate blob data detection data from captured Mat buffer.

- Replace **#TODO: FaceDetection-Blob Detection** with the following code snippet

```cpp
void FaceDetectionClass::matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor , int batchIndex ) {
SizeVector blobSize = blob.get()->dims();
const size_t width = blobSize[0];
const size_t height = blobSize[1];
const size_t channels = blobSize[2];

uint8_t * blob_data = blob->buffer().as<uint8_t *>();

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
### Populate the Inference Request
This method is used populate the inference request and push the frames in to a queue for further processing.

- Replace **#TODO: FaceDetection-populate Inference Request** with the following code snippet.

```cpp
void FaceDetectionClass::enqueue(const cv::Mat &frame) {

   if (!request) {
     request = net.CreateInferRequestPtr();
   }

   width = frame.cols;
   height = frame.rows;

   auto  inputBlob = request->GetBlob(input);
   matU8ToBlob(frame, inputBlob);
   enquedFrames = 1;
}
  ```
### Parse the CNNNetwork from given IR
This method is used to parse the intermediate representation format of CNNNetwork models (that is .bin and .xml files).

- Replace **#TODO: FaceDetection-Parse CNNNetworks** with the following code snippet

```cpp
InferenceEngine::CNNNetwork FaceDetectionClass::read()  {

  InferenceEngine::CNNNetReader netReader;
  /** Read network model **/
  netReader.ReadNetwork(FLAGS_Face_Model);
  /** Set batch size to 1 **/
  netReader.getNetwork().setBatchSize(maxBatch);
  /** Extract model name and load it's weights **/
  std::string binFileName = fileNameNoExt(FLAGS_Face_Model) + ".bin";
  netReader.ReadWeights(binFileName);
  /** Read labels (if any)**/
  std::string labelFileName = fileNameNoExt(FLAGS_Face_Model) + ".labels";

  std::ifstream inputFile(labelFileName);
  std::copy(std::istream_iterator<std::string>(inputFile),
    std::istream_iterator<std::string>(),
    std::back_inserter(labels));

  /** SSD-based network should have one input and one output **/
  // ---------------------------Check inputs -------------------------------------------------
  InferenceEngine::InputsDataMap inputInfo(netReader.getNetwork().getInputsInfo());
  auto& inputInfoFirst = inputInfo.begin()->second;
  inputInfoFirst->setPrecision(Precision::U8);
  inputInfoFirst->getInputData()->setLayout(Layout::NCHW);

  // ---------------------------Check outputs -------------------------------------------------
  InferenceEngine::OutputsDataMap outputInfo(netReader.getNetwork().getOutputsInfo());

  auto& _output = outputInfo.begin()->second;
  output = outputInfo.begin()->first;

  const auto outputLayer = netReader.getNetwork().getLayerByName(output.c_str());

  const int num_classes = outputLayer->GetParamAsInt("num_classes");

  const InferenceEngine::SizeVector outputDims = _output->dims;
  maxProposalCount = outputDims[1];
  objectSize = outputDims[0];

  _output->setPrecision(Precision::FP32);
  _output->setLayout(Layout::NCHW);


  input = inputInfo.begin()->first;
  return netReader.getNetwork();
}

 ```
### Load CNNNetwork for Face detection
Here, we will define a method that will be used for loading the CNNNetworks that will be used for Face detection.
- Replace **#TODO: FaceDetection-LoadNetwork** with the following code snippet

```cpp
void FaceDetectionClass::load(InferenceEngine::InferencePlugin & plg)  {
			net = plg.LoadNetwork(this->read(), {});
			plugin = &plg;
}
```
### Submit inference request and wait for result
Here we will define methods to submit inference request and wait for inference result.
- Replace **#TODO: FaceDetection-submit Inference Request and wait** with the following code snippet

```cpp
void FaceDetectionClass::submitRequest()  {
		if (!enquedFrames) return;
		enquedFrames = 0;
		resultsFetched = false;
		results.clear();
		request->StartAsync();
	}

void FaceDetectionClass::wait() {
		request->Wait(IInferRequest::WaitMode::RESULT_READY);
	}
```
### Fetch Inference Result
This method is used for fetching the inference results.

- Replace **#TODO: FaceDetection-fetch inference result** with the following code snippet


```cpp
void FaceDetectionClass::fetchResults() {

		results.clear();
		if (resultsFetched) return;
		resultsFetched = true;
		const float *detections = request->GetBlob(output)->buffer().as<float *>();

		for (int i = 0; i < maxProposalCount; i++) {
			float image_id = detections[i * objectSize + 0];
			Result r;
			r.label = static_cast<int>(detections[i * objectSize + 1]);
			r.confidence = detections[i * objectSize + 2];
			if (r.confidence <= FLAGS_t) {
				continue;
			}

			r.location.x = detections[i * objectSize + 3] * width;
			r.location.y = detections[i * objectSize + 4] * height;
			r.location.width = detections[i * objectSize + 5] * width - r.location.x;
			r.location.height = detections[i * objectSize + 6] * height - r.location.y;

			if (image_id < 0) {
				break;
			}
			if (FLAGS_r) {
				std::cout << "[" << i << "," << r.label << "] element, prob = " << r.confidence <<
					"    (" << r.location.x << "," << r.location.y << ")-(" << r.location.width << ","
					<< r.location.height << ")"
					<< ((r.confidence > FLAGS_t) ? " WILL BE RENDERED!" : "") << std::endl;
			}

			results.push_back(r);
		}
	}
  ```

### Capture Video Frames 
Till now, we have defined all the required methods for our application development. Now we will start developing our face detection application. First, we need to capture video frames using OpenCV APIs

- Replace **#TODO: Face Detection 2** with the following lines of code

```cpp
     //TODO: Age and Gender Detection 1
    //If there is a single camera connected, just pass 0.
	cv::VideoCapture cap;
	cap.open(0);
	cv::Mat frame;
	cap.read(frame);
     //TODO: Age and Gender Detection 2 
```

### Select GPU for Inferencing Face Detection
Select the plugin device for inference engine where we want to run our inferencing

- Replace **#TODO: Face Detection 3** with the following lines of code


```cpp
    //Select plugins for inference engine
	std::map<std::string, InferencePlugin> pluginsForDevices;

	//Select GPU as plugin device to load Face Detection pre trained optimized model
	InferencePlugin plugin = PluginDispatcher({ "../../../lib/intel64", "" }).getPluginByDevice("GPU");
	pluginsForDevices["GPU"] = plugin;
	//TODO: Age and Gender detection 3
```

### Load Pre-trained Optimized Data Model on GPU
The pre-trained model XML files have been optimized and generated by the Intel® Distribution of OpenVINO™ toolkit model optimizer from the pre-trained models folder. However, participants are expected to experiment with different pre-trained models available.
- Replace **#TODO: Face Detection 4** with the following lines of code

```cpp
    //Load pre trained optimized data model for face detection
	FLAGS_Face_Model = "/opt/intel/computer_vision_sdk/deployment_tools/intel_models/face-detection-adas-0001/FP32/face-detection-adas-0001.xml";

	//Load Face Detection model to target device
	FaceDetectionClass FaceDetection;
	FaceDetection.load(pluginsForDevices["GPU"]);
	//TODO: Age and Gender detection 4

```

### Main Loop for Inferencing
Here we are populating the face detection object for Inference request, and after getting result we draw rectangular box around the face. Also, we use OpenCV APIs for a display window and exit the window.
- Replace **#TODO: Face Detection 5** with the following lines of code

```cpp
    // Main inference loop
	while (true) {
	        //TODO: Cloud Integration 2 
		//Grab the next frame from camera and populate Inference Request
		cap.grab();
		FaceDetection.enqueue(frame);

		//Submit Inference Request for face detection and wait for result
		FaceDetection.submitRequest();
		FaceDetection.wait();

		//TODO: Age and Gender Detection 5

		FaceDetection.fetchResults();

		//TODO: Age and Gender Detection 6

		for (auto & result : FaceDetection.results) {
			cv::Rect rect = result.location;

			//TODO: Age and Gender Detection 7

			// Giving same colour to male and female
			auto rectColor = cv::Scalar(0, 255, 0);

			cv::rectangle(frame, result.location, rectColor, 1);			
		}

		if (-1 != cv::waitKey(1))
			break;

		cv::imshow("Detection results", frame);

		if (!cap.retrieve(frame)) {
			break;
		}
		//TODO: Cloud integration 3
  }
  ```

### The Final Solution
Keep the TODO as it is. We will re-use this program during Age and Gender detection.                 
For complete solution, see [face_detection.cpp](./solutions/facedetection.md)


### Build the Solution and Observe the Output
- Go to ***~/Desktop/Retail/OpenVINO/samples***  directory
- Create a build directory using below command

```bash
$ cd ~/Desktop/Retail/OpenVINO/samples
$ sudo mkdir build
 ```
 - Set the environment variables by using below commands

```bash
$ cd build
$ sudo -s
# source /opt/intel/computer_vision_sdk/bin/setupvars.sh
  ```

- Build the application using cmake and make commands as below         

```bash
# cmake ..
# make
 ```
- Executable will be generated at ***~/Desktop/Retail/OpenVINO/samples/build/intel64/Release*** directory.
- Run the application by using below command. Make sure camera is connected to the device.

```bash
# cd ~/Desktop/Retail/OpenVINO/samples/build/intel64/Release
# ./interactive_face_detection_sample
 ```
 - On successful execution, face will get detected from a live camera feed window.
### Lesson Learnt
Face Detection using the Intel® Distribution of OpenVINO™ toolkit.


## Next Lab
[Age and Gender Detection using Intel® Distribution of OpenVINO™ toolkit](./Age_Gender_Detection.md)
