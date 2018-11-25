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


#include <inference_engine.hpp>
#include "interactive_face_detection.hpp"
#include "mkldnn/mkldnn_extension_ptr.hpp"
#include <opencv2/opencv.hpp>
using namespace InferenceEngine;



struct FaceDetectionClass {

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
	void submitRequest();
	void wait();
	void matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor = 1.0, int batchIndex = 0);
	void enqueue(const cv::Mat &frame);
	InferenceEngine::CNNNetwork read();
	void load(InferenceEngine::InferencePlugin & plg);
	void fetchResults();
};
void FaceDetectionClass::matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor, int batchIndex) {
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
InferenceEngine::CNNNetwork FaceDetectionClass::read() {

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
void FaceDetectionClass::load(InferenceEngine::InferencePlugin & plg) {
	net = plg.LoadNetwork(this->read(), {});
	plugin = &plg;
}
void FaceDetectionClass::submitRequest() {
	if (!enquedFrames) return;
	enquedFrames = 0;
	resultsFetched = false;
	results.clear();
	request->StartAsync();
}

void FaceDetectionClass::wait() {
	request->Wait(IInferRequest::WaitMode::RESULT_READY);
}
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

	void submitRequest();
	void wait();
	void matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor = 1.0, int batchIndex = 0);
	void enqueue(const cv::Mat &face);
	struct Result { float age; float maleProb; };
	Result operator[] (int idx) const {
		auto  genderBlob = request->GetBlob(outputGender);
		auto  ageBlob = request->GetBlob(outputAge);

		return{ ageBlob->buffer().as<float*>()[idx] * 100,
			genderBlob->buffer().as<float*>()[idx * 2 + 1] };
	}
	void load(InferenceEngine::InferencePlugin & plg);
	CNNNetwork read();
};

void AgeGenderDetection::matU8ToBlob(const cv::Mat& orig_image, Blob::Ptr& blob, float scaleFactor, int batchIndex)
{
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
CNNNetwork AgeGenderDetection::read() {

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
void AgeGenderDetection::load(InferenceEngine::InferencePlugin & plg) {
	net = plg.LoadNetwork(this->read(), {});
	plugin = &plg;
}
void AgeGenderDetection::enqueue(const cv::Mat &face) {

	if (!request) {
		request = net.CreateInferRequestPtr();
	}

	auto  inputBlob = request->GetBlob(input);
	matU8ToBlob(face, inputBlob, 1.0f, enquedFaces);
	enquedFaces++;
}
void AgeGenderDetection::submitRequest() {
	if (!enquedFaces) return;

	request->StartAsync();
	enquedFaces = 0;
}

void AgeGenderDetection::wait() {
	if (!request) return;
	request->Wait(IInferRequest::WaitMode::RESULT_READY);
}

//TODO: Define class for HeadPose Detection
//TODO: HeadPose-Blob Detection
//TODO: HeadPose-Parse CNNNetworks
//TODO: HeadPoseDetection buildCameraMatrix
//TODO: HeadPoseDetection-drawAxes
//TODO: HeadPose-LoadNetwork
//TODO: HeadPose-populate Inference Request
//TODO: HeadPose-submit Inference Request and wait


int main(int argc, char *argv[]) {

	//TODO: Cloud integration 1

	int faceCountThreshold = 100;
	int curFaceCount = 0;
	int prevFaceCount = 0;
	int index = 0;
	int malecount = 0;
	int femalecount = 0;
	int attentivityindex = 0;
	int framecounter = 0;
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

	plugin = PluginDispatcher({ "../../../lib/intel64", "" }).getPluginByDevice("CPU");
	pluginsForDevices["CPU"] = plugin;






	//Load pre trained optimized data model for face detection
	FLAGS_Face_Model = "C:\\Intel\\computer_vision_sdk_2018.3.343\\deployment_tools\\intel_models\\face-detection-adas-0001\\FP32\\face-detection-adas-0001.xml";

	//Load Face Detection model to target device
	FaceDetectionClass FaceDetection;
	FaceDetection.load(pluginsForDevices["GPU"]);

	FLAGS_Age_Gender_Model = "C:\\Intel\\computer_vision_sdk_2018.3.343\\deployment_tools\\intel_models\\age-gender-recognition-retail-0013\\FP32\\age-gender-recognition-retail-0013.xml";
	AgeGenderDetection AgeGender;
	AgeGender.load(pluginsForDevices["CPU"]);

	//TODO: HeadPose Detection 1




	// Main inference loop
	while (true) {
	         //TODO: Cloud Integration 2
		//Grab the next frame from camera and populate Inference Request
		cap.grab();
		FaceDetection.enqueue(frame);

		//Submit Inference Request for face detection and wait for result
		FaceDetection.submitRequest();
		FaceDetection.wait();

		//Submit Inference Request for age and gender detection and wait for result
		AgeGender.submitRequest();
		AgeGender.wait();

		//TODO: HeadPose Detection 2


		FaceDetection.fetchResults();

		//Clipped the identified face and send Inference Request for age and gender detection
		for (auto face : FaceDetection.results) {
			auto clippedRect = face.location & cv::Rect(0, 0, 640, 480);
			auto face1 = frame(clippedRect);
			AgeGender.enqueue(face1);
			//TODO: HeadPose Detection 3
		}

		// Got the Face, Age and Gender detection result, now customize and print them on window
		std::ostringstream out;
		index = 0;
		curFaceCount = 0;
		malecount = 0;
		femalecount = 0;
		attentivityindex = 0;

		for (auto & result : FaceDetection.results) {
			cv::Rect rect = result.location;

			out.str("");
			curFaceCount++;

			//Draw rectangle bounding identified face and print Age and Gender
			out << (AgeGender[index].maleProb > 0.5 ? "M" : "F");

			if (AgeGender[index].maleProb > 0.5)
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
			//TODO: HeadPose Detection 4
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
		//TODO: Cloud integration 3
	}
	return 0;
}

```
