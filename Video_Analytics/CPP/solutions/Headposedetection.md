```CPP
#include <gflags/gflags.h>
#include <functional>
#include <iostream>
#include <fstream>
#include <random>
#include <memory>
#include <chrono>
#include <vector>
#include <string>
#include <utility>
#include <algorithm>
#include <iterator>
#include <map>
#include <inference_engine.hpp>
#include <samples/ocv_common.hpp>
#include <samples/slog.hpp>
#include "interactive_face_detection.hpp"
#include "detectors.hpp"
#include <ie_iextension.h>
#include <ext_list.hpp>

using namespace InferenceEngine;

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
	const size_t width = (size_t)cap.get(cv::CAP_PROP_FRAME_WIDTH);
	const size_t height = (size_t)cap.get(cv::CAP_PROP_FRAME_HEIGHT);


	//Select plugins for inference engine
	std::map<std::string, InferencePlugin> pluginsForDevices;

	//Select GPU as plugin device to load Face Detection pre trained optimized model
	InferencePlugin plugin = PluginDispatcher({ "../../../lib/intel64", "" }).getPluginByDevice("GPU");
	pluginsForDevices["GPU"] = plugin;

	//Select CPU as plugin device to load Age and Gender Detection pre trained optimized model
	plugin = PluginDispatcher({ "../../../lib/intel64", "" }).getPluginByDevice("CPU");
	pluginsForDevices["CPU"] = plugin;


	//Load pre trained optimized data model for face detection
	FLAGS_Face_Model = "/opt/intel/computer_vision_sdk/deployment_tools/intel_models/face-detection-adas-0001/FP32/face-detection-adas-0001.xml";
	FaceDetection faceDetector(FLAGS_Face_Model, FLAGS_d, 1, false, FLAGS_async, FLAGS_t, FLAGS_r);
	//Load Face Detection model to target device

	faceDetector.load(pluginsForDevices["GPU"]);
	FLAGS_Age_Gender_Model = "/opt/intel/computer_vision_sdk/deployment_tools/intel_models/age-gender-recognition-retail-0013/FP32/age-gender-recognition-retail-0013.xml";
	AgeGenderDetection ageGenderDetector(FLAGS_Age_Gender_Model, FLAGS_d_ag, FLAGS_n_ag, FLAGS_dyn_ag, FLAGS_async);
	ageGenderDetector.load(pluginsForDevices["CPU"]);
	FLAGS_m_hp = "/opt/intel/computer_vision_sdk/deployment_tools/intel_models/head-pose-estimation-adas-0001/FP32/head-pose-estimation-adas-0001.xml";
  	HeadPoseDetection headPoseDetector(FLAGS_m_hp, FLAGS_d_hp, FLAGS_n_hp, FLAGS_dyn_hp, FLAGS_async);
	headPoseDetector.load(pluginsForDevices["CPU"]);

	// Main inference loop
	while (true) {
		//TODO: Cloud integration 2
		//Grab the next frame from camera and populate Inference Request
		cap.grab();
		faceDetector.enqueue(frame);

		//Submit Inference Request for face detection and wait for result
		faceDetector.submitRequest();
		faceDetector.wait();

		//Submit Inference Request for age and gender detection and wait for result
		ageGenderDetector.submitRequest();
		ageGenderDetector.wait();
		//Submit Inference Request for HeadPose detection and wait for result
		headPoseDetector.submitRequest();
		headPoseDetector.wait();


		faceDetector.fetchResults();

		//Clipped the identified face and send Inference Request for age and gender detection
		for (auto face : faceDetector.results) {
			auto clippedRect = face.location & cv::Rect(0, 0, width, height);
			auto face1 = frame(clippedRect);
			ageGenderDetector.enqueue(face1);
			headPoseDetector.enqueue(face1);
		}
		// Got the Face, Age and Gender detection result, now customize and print them on window
		std::ostringstream out;
		index = 0;
		curFaceCount = 0;
		malecount = 0;
		femalecount = 0;
		attentivityindex = 0;

		for (auto & result : faceDetector.results) {
			cv::Rect rect = result.location;

			out.str("");
			curFaceCount++;
			//Draw rectangle bounding identified face and print Age and Gender
			out << (ageGenderDetector[index].maleProb > 0.5 ? "M" : "F");
			if (ageGenderDetector[index].maleProb > 0.5)
				malecount++;
			else
				femalecount++;
			out << "," << static_cast<int>(ageGenderDetector[index].age);
			cv::putText(frame, out.str(), cv::Point2f(result.location.x, result.location.y - 15), cv::FONT_HERSHEY_COMPLEX_SMALL, 0.8, cv::Scalar(0, 0, 255));
			if (index < headPoseDetector.maxBatch) {
				cv::Point3f center(rect.x + rect.width / 2, rect.y + rect.height / 2, 0);
				headPoseDetector.drawAxes(frame, center, headPoseDetector[index], 50);
				if (headPoseDetector.yaw > -0.4 && headPoseDetector.yaw < -0.001)
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
