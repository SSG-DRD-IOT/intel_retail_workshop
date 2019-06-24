```cpp
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
		FLAGS_d = "MYRIAD";
		//Select plugins for inference engine
		std::map<std::string, InferencePlugin> pluginsForDevices;

		//Select GPU as plugin device to load Face Detection pre trained optimized model
		InferencePlugin plugin = PluginDispatcher().getPluginByDevice(FLAGS_d);
		if ((FLAGS_d.find("CPU") != std::string::npos)) {
			plugin.AddExtension(std::make_shared<Extensions::Cpu::CpuExtensions>());

		}  
		pluginsForDevices[FLAGS_d] = plugin;
		//TODO: Age and Gender Detection 3


		//Load pre trained optimized data model for face detection
		FLAGS_Face_Model = "C:\\Program Files (x86)\\IntelSWTools\\openvino\\deployment_tools\\tools\\model_downloader\\Transportation\\object_detection\\face\\pruned_mobilenet_reduced_ssd_shared_weights\\dldt\\face-detection-adas-0001-fp16.xml";
		FaceDetection faceDetector(FLAGS_Face_Model, FLAGS_d, 1, false, FLAGS_async, FLAGS_t, FLAGS_r);
		faceDetector.load(pluginsForDevices[FLAGS_d]);


		Timer timer;
		size_t framesCounter = 0;
		bool isLastFrame;
		bool frameReadStatus;
		cv::Mat prev_frame, next_frame;
		bool isModeChanged = false;

		// Reading the next frame
		frameReadStatus = cap.read(frame);



		//TODO: Age and Gender Detection 4


		// Main inference loop
		while (true) {
			timer.start("total");
			framesCounter++;
			isLastFrame = !frameReadStatus;
			//TODO: Cloud integration 2


			// No valid frame to infer if previous frame is the last
			if (!isLastFrame) {
				faceDetector.enqueue(frame);
				faceDetector.submitRequest();
			}
			faceDetector.wait();

			//TODO: Age and Gender Detection 5
			faceDetector.fetchResults();

			if (!isLastFrame) {
				frameReadStatus = cap.read(next_frame);
			}
			//TODO: Age and Gender Detection 6

			for (auto & result : faceDetector.results) {
				cv::Rect rect = result.location;

				//TODO: Age and Gender Detection 7

				// Giving same colour to male and female
				auto rectColor = cv::Scalar(0, 255, 0);

				cv::rectangle(next_frame, result.location, rectColor, 1);
			}
			std::ostringstream out;
			out << "Wallclock time " << (faceDetector.isAsync ? "(TRUE ASYNC)      " : "(SYNC, press Tab) ");
			cv::putText(next_frame, out.str(), cv::Point2f(10, 50), cv::FONT_HERSHEY_TRIPLEX, 0.6, cv::Scalar(0, 0, 255));
			out.str("");
			out << "Total image throughput: " << std::fixed << std::setprecision(2)
				<< 1000.f / (timer["total"].getSmoothedDuration()) << " fps";
			cv::putText(next_frame, out.str(), cv::Point2f(10, 20), cv::FONT_HERSHEY_TRIPLEX, 0.6,
				cv::Scalar(255, 0, 0));
			prev_frame = frame;
			frame = next_frame;
			next_frame = cv::Mat();
			timer.finish("total");
			const int key = cv::waitKey(1);
			if (27 == key)  // Esc
				break;

			cv::imshow("Detection results", frame);

			if (!cap.retrieve(frame)) {
				break;
			}

			if (9 == key) {  // Tab
				faceDetector.isAsync ^= true;

			}


			//TODO: Cloud integration 3
		}

	return 0;
}
```
