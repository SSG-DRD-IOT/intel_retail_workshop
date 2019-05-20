```python
#!/usr/bin/env python


from __future__ import print_function
#TODO Import Cloud_Integration packages
import sys
import os
from argparse import ArgumentParser
import cv2
import time
import numpy as np
import math
import logging as log
from openvino.inference_engine import IENetwork, IEPlugin
CV_PI=3.1415926535897932384626433832795

def build_argparser():
    parser = ArgumentParser()
    parser.add_argument("-m", "--model", help="Path to an .xml file with a trained model.", required=True, type=str)
    parser.add_argument("-d", "--device",
                        help="Specify the target device to infer on; CPU, GPU, FPGA or MYRIAD is acceptable. Demo "
                             "will look for a suitable plugin for device specified (CPU by default)", default="CPU",
                        type=str)
    parser.add_argument("-m_ag", "--ag_model", help="Path to an .xml file with a trained model.", default=None, type=str)
    parser.add_argument("-d_ag", "--device_ag", help="Target device for Age/Gender Recognition network (CPU, GPU, FPGA, or MYRIAD). The demo will look for a suitable plugin for a specified device. (CPU by default)", default="CPU",
                        type=str)
    #TODO Head_Pose command line arguments				
    parser.add_argument("-i", "--input",
                        help="Path to video file or image. 'cam' for capturing video stream from camera", required=True,
                        type=str)
    parser.add_argument("-l", "--cpu_extension",
                        help="MKLDNN (CPU)-targeted custom layers.Absolute path to a shared library with the kernels "
                             "impl.", type=str, default=None)
    parser.add_argument("-pp", "--plugin_dir", help="Path to a plugin folder", type=str, default=None)  
    parser.add_argument("--labels", help="Labels mapping file", default=None, type=str)
    parser.add_argument("-pt", "--prob_threshold", help="Probability threshold for detections filtering",
                        default=0.5, type=float)
    parser.add_argument("-no_show", "--no_show", help="do not show processed video",
                        default=False, action="store_true")
    parser.add_argument("-r", "--raw", help="raw_output_message",
                        default=False, action="store_true")
    return parser

#TODO Head_Pose_Detection 1
def load_model(feature,model_xml,device,plugin_dirs,input_key_length,output_key_length,cpu_extension):

    model_bin = os.path.splitext(model_xml)[0] + ".bin"


    log.info("Initializing plugin for {} device...".format(device))
    plugin = IEPlugin(device, plugin_dirs)

    log.info("Loading network files for {}".format(feature))
    if cpu_extension and 'CPU' in device:
        plugin.add_cpu_extension(cpu_extension)
    else:
        plugin.set_config({"PERF_COUNT":"YES"})

    net = IENetwork(model=model_xml, weights=model_bin)

    if plugin.device == "CPU":
        supported_layers = plugin.get_supported_layers(net)
        not_supported_layers = [l for l in net.layers.keys() if l not in supported_layers]
        if len(not_supported_layers) != 0:
            log.error("Following layers are not supported by the plugin for specified device {}:\n {}".
		  format(plugin.device, ', '.join(not_supported_layers)))
            log.error("Please try to specify cpu extensions library path in demo's command line parameters using -l "
		  "or --cpu_extension command line argument")
            sys.exit(1)


    log.info("Checking {} network inputs".format(feature))
    assert len(net.inputs.keys()) == input_key_length, "Demo supports only single input topologies"
    log.info("Checking {} network outputs".format(feature))
    assert len(net.outputs) == output_key_length, "Demo supports only single output topologies"

    return plugin,net


def main():
    log.basicConfig(format="[ %(levelname)s ] %(message)s", level=log.INFO, stream=sys.stdout)
    args = build_argparser().parse_args()
    age_enabled = False
    headPose_enabled = False
    #TODO Cloud_Integration 2



    MYRIAD_plugin = IEPlugin(args.device.upper(),args.plugin_dir)
    MYRIAD_plugin_ag = IEPlugin(args.device_ag.upper(),args.plugin_dir)
    #TODO Initializing Plugin for Myraid for Head Pose


    log.info("Reading IR...")
    # Face detection
    #log.info("Loading network files for Face Detection")

    plugin,net=load_model("Face Detection",args.model,args.device.upper(),args.plugin_dir,1,1,args.cpu_extension)
    input_blob = next(iter(net.inputs))
    out_blob = next(iter(net.outputs))

    if (args.device.upper() == "MYRIAD"):
        exec_net = MYRIAD_plugin.load(network=net, num_requests=2)
    else :
        exec_net = plugin.load(network=net, num_requests=2)

    n, c, h, w = net.inputs[input_blob].shape
    del net

    # age and gender   
    if args.model and args.ag_model:

       age_enabled =True
       #log.info("Loading network files for Age/Gender Recognition")
       plugin,ag_net=load_model("Age/Gender Recognition",args.ag_model,args.device_ag.upper(),args.plugin_dir,1,2,args.cpu_extension)
       age_input_blob=next(iter(ag_net.inputs))
       age_out_blob=next(iter(ag_net.outputs))


       if ((args.device_ag.upper() == "MYRIAD") and (not args.device.upper() == "MYRIAD")):
           age_exec_net = MYRIAD_plugin_ag.load(network=ag_net, num_requests=2)
       elif (args.device_ag == "MYRIAD"):
           age_exec_net = MYRIAD_plugin.load(network=ag_net, num_requests=2)
       else :
           age_exec_net = plugin.load(network=ag_net, num_requests=2)      


       ag_n, ag_c, ag_h, ag_w = ag_net.inputs[input_blob].shape
       del ag_net

   #TODO Head_Pose_Detection 2
    total_start = time.time()

    if args.input == 'cam':
       input_stream = 0
    else:
        input_stream = args.input
        assert os.path.isfile(args.input), "Specified input file doesn't exist"
    if args.labels:
       with open(args.labels, 'r') as f:
            labels_map = [x.strip() for x in f]
    else:
        labels_map = None

    cap = cv2.VideoCapture(input_stream)
    if not cap.isOpened():
        log.error("Cannot open input file")
        sys.exit(1)
    cur_request_id = 0
    log.info("Starting inference ...")
    log.info("To stop the demo execution press Esc button")
    is_async_mode = True
    render_time = 0
    curFaceCount = 0
    prevFaceCount = 0
    index = 0
    malecount = 0
    femalecount = 0
    attentivityindex = 0

    decode_time = 0
    visual_time = 0
    framesCounter = 0
    decode_prev_start = time.time()
    ret, frame = cap.read()
    decode_prev_finish = time.time()
    decode_prev_time = decode_prev_finish - decode_prev_start
    while cap.isOpened():
        curFaceCount = 0
        malecount=0
        femalecount = 0
        attentivityindex=0
        analytics_time = 0
        decode_next_start = time.time()
        ret, frame = cap.read()
        decode_next_finish = time.time()
        decode_next_time = decode_next_finish - decode_next_start
        if not ret:
            break

        framesCounter+=1
        initial_w = cap.get(3)
        initial_h = cap.get(4)

        inf_start = time.time()
        in_frame = cv2.resize(frame, (w, h))
        in_frame = in_frame.transpose((2, 0, 1))  # Change data layout from HWC to CHW
        in_frame = in_frame.reshape((n, c, h, w))
        exec_net.start_async(request_id=cur_request_id, inputs={input_blob: in_frame})            
        if exec_net.requests[cur_request_id].wait(-1) == 0:
            inf_end = time.time()
            det_time = inf_end - inf_start

            #analytics_start_time =time.time()
            # Parse detection results of the current request
            res = exec_net.requests[cur_request_id].outputs[out_blob]
            for obj in res[0][0]:

                # Draw only objects when probability more than specified threshold
                if obj[2] > args.prob_threshold:
                    xmin = int(obj[3] * initial_w)
                    ymin = int(obj[4] * initial_h)
                    xmax = int(obj[5] * initial_w)
                    ymax = int(obj[6] * initial_h)


                    #Crop the face rectangle for further processing
                    clippedRect = frame[ymin:ymax, xmin:xmax]  
                    if (clippedRect.size)==0:
                       continue                     			

                    height = ymax - ymin
                    width = xmax -xmin  

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


                    visual_start = time.time()                                   
                    if args.no_show==False:    
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

                        class_id = int(obj[1])                                     
                        # Draw box and label\class_id
                        color = (min(class_id * 12.5, 255), min(class_id * 7, 255), min(class_id * 5, 255))
                        cv2.rectangle(frame, (xmin, ymin), (xmax, ymax), (255,10,10), 2)
                        det_label = labels_map[class_id] if labels_map else str(class_id)
                        #TODO Head_Pose_Detection 4

                        render_time_message = "OpenCV cap/rendering time: {:.2f} ms".format(render_time * 1000)
                        inf_time_message = "Face Detection time: {:.2f} ms ({:.2f} fps)".format((det_time * 1000),1/(det_time))           
                        if (clippedRect.size)!= 0 and analytics_time:
                            Face_analytics_time_message = "Face Analytics Networks time: {:.2f} ms ({:.2f} fps)".format((analytics_time * 1000),1/(analytics_time))
                        else:
                            Face_analytics_time_message = "Face Analytics Networks time: {:.2f} ms".format((analytics_time * 1000))

                        cv2.putText(frame, render_time_message, (15, 15), cv2.FONT_HERSHEY_COMPLEX, 0.5, (255, 10, 10), 1)
                        cv2.putText(frame, inf_time_message, (15, 30), cv2.FONT_HERSHEY_COMPLEX, 0.5, (255, 10, 10), 1)
                        #if age_enabled or headPose_enabled or emotions_enabled or landmarks_enabled:
                        if age_enabled or headPose_enabled:
                            cv2.putText(frame, Face_analytics_time_message, (15,45), cv2.FONT_HERSHEY_COMPLEX, 0.5, (255, 10, 10), 1)

                        # Rendering time
                        cv2.imshow("Detection Results", frame)
                        visual_end = time.time()
                        visual_time = visual_end - visual_start

                        render_end = time.time()
                        render_time = decode_prev_time + decode_next_time + visual_time


            key = cv2.waitKey(1)
            if key == 27:
                break
    #TODO Cloud_Integration 3
    total_finish = time.time()
    total= total_finish - total_start
    print("Total image throughput: ({:.2f} fps)".format(framesCounter*(1/total)))


    cv2.destroyAllWindows()
    log.info("Number of processed frames: {}".format(framesCounter))
    del exec_net
    del plugin
    log.info("Execution successful")

if __name__ == '__main__':
    sys.exit(main() or 0)
```
