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

//TODO: Define class for Age & Gender Detection
//TODO: AgeGender-Blob Detection
//TODO: AgeGenderDetection-Parse CNNNetworks
//TODO: AgeGenderDetection-LoadNetwork
//TODO: AgeGenderDetection-populate Inference Request
//TODO: AgeGenderDetection-submit Inference Request and wait

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

	//TODO: Age and Gender Detection 1
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
	//TODO: Age and Gender Detection 2




	//Load pre trained optimized data model for face detection
	FLAGS_Face_Model = "C:\\Intel\\computer_vision_sdk_2018.3.343\\deployment_tools\\intel_models\\face-detection-adas-0001\\FP32\\face-detection-adas-0001.xml";

	//Load Face Detection model to target device
	FaceDetectionClass FaceDetection;
	FaceDetection.load(pluginsForDevices["GPU"]);
	//TODO: Age and Gender Detection 3





	// Main inference loop
	while (true) {
		//Grab the next frame from camera and populate Inference Request
		cap.grab();
		FaceDetection.enqueue(frame);

		//Submit Inference Request for face detection and wait for result
		FaceDetection.submitRequest();
		FaceDetection.wait();

		//TODO: Age and Gender Detection 4


		FaceDetection.fetchResults();

		//TODO: Age and Gender Detection 5

		for (auto & result : FaceDetection.results) {
			cv::Rect rect = result.location;

			//TODO: Age and Gender Detection 6

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
		//TODO: Cloud integration 2
	}
	return 0;
}


```
