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
void HeadPoseDetection::buildCameraMatrix(int cx, int cy, float focalLength) {
	if (!cameraMatrix.empty()) return;
	cameraMatrix = cv::Mat::zeros(3, 3, CV_32F);
	cameraMatrix.at<float>(0) = focalLength;
	cameraMatrix.at<float>(2) = static_cast<float>(cx);
	cameraMatrix.at<float>(4) = focalLength;
	cameraMatrix.at<float>(5) = static_cast<float>(cy);
	cameraMatrix.at<float>(8) = 1;
}
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
void HeadPoseDetection::load(InferenceEngine::InferencePlugin & plg) {

	net = plg.LoadNetwork(this->read(), {});
	plugin = &plg;

}
void HeadPoseDetection::enqueue(const cv::Mat &face) {

	if (!request) {
		request = net.CreateInferRequestPtr();
	}

	Blob::Ptr  inputBlob = request->GetBlob(input);

	matU8ToBlob(face, inputBlob, 1.0f, enquedFaces);

	enquedFaces++;
}
void HeadPoseDetection::submitRequest() {
	if (!enquedFaces) return;
	request->StartAsync();
	enquedFaces = 0;
}

void HeadPoseDetection::wait() {
	if (!request) return;
	request->Wait(IInferRequest::WaitMode::RESULT_READY);
}


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

	FLAGS_m_hp = "C:\\Intel\\computer_vision_sdk_2018.3.343\\deployment_tools\\intel_models\\head-pose-estimation-adas-0001\\FP32\\head-pose-estimation-adas-0001.xml";
	HeadPoseDetection HeadPose;
	HeadPose.load(pluginsForDevices["CPU"]);





	// Main inference loop
	while (true) {
		//TODO: Cloud Integration 2
		//Grab the next frame from camera and populate Inference Request
		framecounter++;
		cap.grab();
		FaceDetection.enqueue(frame);

		//Submit Inference Request for face detection and wait for result
		FaceDetection.submitRequest();
		FaceDetection.wait();

		//Submit Inference Request for age and gender detection and wait for result
		AgeGender.submitRequest();
		AgeGender.wait();

		//Submit Inference Request for HeadPose detection and wait for result
		HeadPose.submitRequest();
		HeadPose.wait();


		FaceDetection.fetchResults();

		//Clipped the identified face and send Inference Request for age and gender detection
		for (auto face : FaceDetection.results) {
			auto clippedRect = face.location & cv::Rect(0, 0, 640, 480);
			auto face1 = frame(clippedRect);
			AgeGender.enqueue(face1);
			HeadPose.enqueue(face1);
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

			if (index < HeadPose.maxBatch) {

				cv::Point3f center(rect.x + rect.width / 2, rect.y + rect.height / 2, 0);
				HeadPose.drawAxes(frame, center, HeadPose[index], 50);
				if (HeadPose.yaw > -0.4 && HeadPose.yaw < -0.001)
				{
					attentivityindex++;

				}
			}
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
