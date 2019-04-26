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

	//TODO: Age and Gender Detection 1
	//If there is a single camera connected, just pass 0.
	cv::VideoCapture cap;
	cap.open(0);
	cv::Mat frame;
	cap.read(frame);
//TODO: Age and Gender Detection 2

	//Select plugins for inference engine
	std::map<std::string, InferencePlugin> pluginsForDevices;

	//Select GPU as plugin device to load Face Detection pre trained optimized model
	InferencePlugin plugin = PluginDispatcher({ "../../../lib/intel64", "" }).getPluginByDevice("GPU");
	pluginsForDevices["GPU"] = plugin;
	//TODO: Age and Gender Detection 3


	//Load pre trained optimized data model for face detection
	FLAGS_Face_Model = "C:\\Intel\\computer_vision_sdk\\deployment_tools\\intel_models\\face-detection-adas-0001\\FP32\\face-detection-adas-0001.xml";
	FaceDetection faceDetector(FLAGS_Face_Model, FLAGS_d, 1, false, FLAGS_async, FLAGS_t, FLAGS_r);
	faceDetector.load(pluginsForDevices["GPU"]);
	//TODO: Age and Gender Detection 4


	// Main inference loop
	while (true) {
		//TODO: Cloud integration 2
		//Grab the next frame from camera and populate Inference Request
		cap.grab();
		faceDetector.enqueue(frame);

		//Submit Inference Request for face detection and wait for result
		faceDetector.submitRequest();
		faceDetector.wait();

		//TODO: Age and Gender Detection 5
		faceDetector.fetchResults();

		//TODO: Age and Gender Detection 6

		for (auto & result : faceDetector.results) {
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
	return 0;
}


```
