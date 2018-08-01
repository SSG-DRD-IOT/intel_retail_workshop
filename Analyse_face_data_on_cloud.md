# Analyze Face Data on Cloud
### Lab Overview
We have done Face, Age and Gender Detection in our previous modules. We have successfully counted number of faces so far.     
In this module we will publish this data to local cloud for analysis.   
We include the following points
- Declare a device id that will be used for publishing the data to cloud
- Integrate a python script for publishing the data to cloud
- Publish the number of faces after showing the face count
- Login to cloud and view charts showing the number of faces

### Declare the Device Id
- Replace #TODO: Cloud Integration 1
- Paste the following line and replace the device id “1234” with your device id written on your computer.
```
std::string deviceId = “1234”;
 ```

### Publish Number of Faces to Cloud
We counted the number of faces successfully. Now, we will publish it to cloud for analysis.
**Note:** We are not publishing video stream or pictures of the screen. We are only publishing the number of faces. For publishing the data to cloud we will be integrating a python script.
- The following content should be present in a python script called as “cloud.py” and copied to the ***Desktop > Retail > OpenVINO***
- Add the following python script (cloud.py) to your system.

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

with open('file.json', 'w') as file:
     file.write(json.dumps(count))

resp = requests.get('http://10.138.77.101:9002/analytics/face?'+ query);

if resp.status_code != 201:
  print("Unable to submit the data")
else:
  print("Data Submitted for analysis")
 ```
### Visualizing your Data on the Cloud
Real time visualization of number of people, age and gender on local cloud
- Go to http://<cloud server url>:9002
- Example : 127.0.0.1:9002
- Enter your device id
- Click the plot
- See the real time face count on cloud

![](images/facecount on cloud.png)

###  Final Solution
For complete solution look into the below code which includes Face, Age and Gender detection using OpenVINO.
```
#include <gflags/gflags.h>
#include <functional>
#include <iostream>
#include <fstream>
#include <random>
#include <memory>
#include <chrono>
#include <string>
#include <utility>
#include <algorithm>
#include <iterator>
#include <samples/common.hpp>
#include <samples/slog.hpp>
#include <ext_list.hpp>
#include <sstream>
#include <map>
#include <vector>
#include "mkldnn/mkldnn_extension_ptr.hpp"
#include <inference_engine.hpp>
#include "interactive_face_detection.hpp"
#include <opencv2/opencv.hpp>

using namespace InferenceEngine;



struct FaceDetectionClass  {



	ExecutableNetwork net;
	InferenceEngine::InferencePlugin * plugin;
	InferRequest::Ptr request;
	std::string & commandLineFlag = FLAGS_Face_Model;
	std::string topoName = "Face Detection";
	const int maxBatch = 1;

	ExecutableNetwork* operator ->() {
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

	void submitRequest()  {
		if (!enquedFrames) return;
		enquedFrames = 0;
		resultsFetched = false;
		results.clear();
		request->StartAsync();
	}

	 void wait() {

		request->Wait(IInferRequest::WaitMode::RESULT_READY);
	}

	void matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor = 1.0, int batchIndex = 0) {
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

	void enqueue(const cv::Mat &frame) {

		if (!request) {

			request = net.CreateInferRequestPtr();
		}

		width = frame.cols;
		height = frame.rows;

		auto  inputBlob = request->GetBlob(input);

		matU8ToBlob(frame, inputBlob);

		enquedFrames = 1;
	}


	InferenceEngine::CNNNetwork read()  {

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
		// ---------------------------Check inputs ------------------------------------------------------
		InferenceEngine::InputsDataMap inputInfo(netReader.getNetwork().getInputsInfo());
		auto& inputInfoFirst = inputInfo.begin()->second;
		inputInfoFirst->setPrecision(Precision::U8);
		inputInfoFirst->getInputData()->setLayout(Layout::NCHW);

		// ---------------------------Check outputs ------------------------------------------------------
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

	void into(InferenceEngine::InferencePlugin & plg)  {

			net = plg.LoadNetwork(this->read(), {});
			plugin = &plg;

	}

	void fetchResults() {

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
};

struct AgeGenderDetection {
	std::string input;
	std::string outputAge;
	std::string outputGender;
	int enquedFaces = 0;


	ExecutableNetwork net;
	InferenceEngine::InferencePlugin * plugin;
	InferRequest::Ptr request;
	std::string & commandLineFlag = FLAGS_Age_Gender_Model;
	std::string topoName = "Age Gender";
	const int maxBatch = FLAGS_n_ag;



	void submitRequest()  {
		if (!enquedFaces) return;
		request->StartAsync();
		enquedFaces = 0;
	}

	void wait() {
		if (!request) return;
		request->Wait(IInferRequest::WaitMode::RESULT_READY);
	}

	void matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor = 1.0, int batchIndex = 0) {
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


	void enqueue(const cv::Mat &face) {

		if (!request) {
			request = net.CreateInferRequestPtr();
		}

		auto  inputBlob = request->GetBlob(input);
		matU8ToBlob(face, inputBlob, 1.0f, enquedFaces);
		enquedFaces++;
	}

	struct Result { float age; float maleProb; };
	Result operator[] (int idx) const {
		auto  genderBlob = request->GetBlob(outputGender);
		auto  ageBlob = request->GetBlob(outputAge);

		return{ ageBlob->buffer().as<float*>()[idx] * 100,
			genderBlob->buffer().as<float*>()[idx * 2 + 1] };
	}

	void into(InferenceEngine::InferencePlugin & plg)  {

			net = plg.LoadNetwork(this->read(), {});
			plugin = &plg;

	}

	CNNNetwork read()  {

		InferenceEngine::CNNNetReader netReader;
		/** Read network model **/
		netReader.ReadNetwork(FLAGS_Age_Gender_Model);

		//	/** Set batch size to 16
		netReader.getNetwork().setBatchSize(16);

		/** Extract model name and load it's weights **/
		std::string binFileName = fileNameNoExt(FLAGS_Age_Gender_Model) + ".bin";
		netReader.ReadWeights(binFileName);

		/** Age Gender network should have one input two outputs **/
		InferenceEngine::InputsDataMap inputInfo(netReader.getNetwork().getInputsInfo());

		auto& inputInfoFirst = inputInfo.begin()->second;
		inputInfoFirst->setPrecision(Precision::FP32);
		inputInfoFirst->getInputData()->setLayout(Layout::NCHW);
		input = inputInfo.begin()->first;

		// ---------------------------Check outputs ------------------------------------------------------
		InferenceEngine::OutputsDataMap outputInfo(netReader.getNetwork().getOutputsInfo());

		auto it = outputInfo.begin();
		auto ageOutput = (it++)->second;
		auto genderOutput = (it++)->second;

		outputAge = ageOutput->name;
		outputGender = genderOutput->name;
		return netReader.getNetwork();
	}
};



int main(int argc, char *argv[]) {
	int faceCountThreshold = 100;
	int curFaceCount = 0;
	int prevFaceCount = 0;
	int index = 0;
	int malecount=0;
	int femalecount=0;
	std::string id = "1234";

	//If there is a single camera connected, just pass 0.
	cv::VideoCapture cap;
	cap.open(0);

	cv::Mat frame;
	cap.read(frame);

	//Select plugins for inference engine
	std::map<std::string, InferencePlugin> pluginsForDevices;

	//Select GPU as plugin device to load Face Detection pre trained optimized model
	InferencePlugin plugin = PluginDispatcher({ "../../../lib/intel64", "" }).getPluginByDevice("GPU");
	pluginsForDevices["GPU"] = plugin;

	//Select GPU as plugin device to load Age and Gender Detection pre trained optimized model
	plugin = PluginDispatcher({ "../../../lib/intel64", "" }).getPluginByDevice("CPU");
	pluginsForDevices["CPU"] = plugin;


	//Load pre trained optimized data model for face detection
	FLAGS_Face_Model = "/opt/intel/computer_vision_sdk_2018.1.265/deployment_tools/intel_models/face-detection-adas-0001/FP16/face-detection-adas-0001.xml";


	FaceDetectionClass FaceDetection;
	FaceDetection.into(pluginsForDevices["GPU"]);

	//Load pre trained optimized data model for Age and Gender detection
	FLAGS_Age_Gender_Model = "/opt/intel/computer_vision_sdk_2018.1.265/deployment_tools/intel_models/age-gender-recognition-retail-0013/FP32/age-gender-recognition-retail-0013.xml";
	AgeGenderDetection AgeGender;
	AgeGender.into(pluginsForDevices["CPU"]);


	// Main inference loop
	while (true) {
		//Grab the next frame from camera and populate Inference Request
		cap.grab();
		FaceDetection.enqueue(frame);

		//Submit Inference Request for face detection and wait for result
		FaceDetection.submitRequest();
		FaceDetection.wait();

		//Submit Inference Request for age and gender detection and wait for result
		AgeGender.submitRequest();
		AgeGender.wait();

		FaceDetection.fetchResults();
		//Clipped the identified face and send Inference Request for age and gender detection
		for (auto face : FaceDetection.results) {
			auto clippedRect = face.location & cv::Rect(0, 0, 640, 480);
			auto face1 = frame(clippedRect);
			AgeGender.enqueue(face1);
		}
		// Got the Face, Age and Gender detection result, now customize and print them on window
		std::ostringstream out;
		index = 0;
		curFaceCount = 0;
		malecount=0;
		femalecount=0;

		for (auto & result : FaceDetection.results) {
			cv::Rect rect = result.location;

			out.str("");
			curFaceCount++;

			//Draw rectangle bounding identified face and print Age and Gender
			out << (AgeGender[index].maleProb > 0.5 ? "M" : "F");
			if(AgeGender[index].maleProb > 0.5)
				malecount++;
			else
				femalecount++;

			out << "," << static_cast<int>(AgeGender[index].age);

			cv::putText(frame,
				out.str(),
				cv::Point2f(result.location.x, result.location.y - 15),
				cv::FONT_HERSHEY_COMPLEX_SMALL,
				0.8,
				cv::Scalar(0, 0, 255));

			index++;

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

		//Submit data to cloud when there is change in face count
		if (curFaceCount != prevFaceCount && curFaceCount < faceCountThreshold)
		{
			prevFaceCount = curFaceCount;

			//Integrate python module to submit data to cloud
			std::string cmd = "/home/intel/Desktop/Retail/OpenVINO/cloud.py " + id + " " + std::to_string(curFaceCount);
			int systemRet = std::system(cmd.c_str());
			if (systemRet == -1)
			slog::info << "System fails : " <<slog::endl;
			slog::info << "Number of faces in the frame are : " << curFaceCount << slog::endl;
			slog::info << "male count is " << malecount << slog::endl;
			slog::info << "female count is " << femalecount << slog::endl;
		}
	}
	return 0;
}

 ```
### Lesson Learnt
Interfacing OpenVINO™ toolkit with cloud and visualizing data on cloud.
