# Simple Video Decoder

## Introduction

We will build a custom Console application which performs decoding of elementary compressed video stream and renders them on the screen:

*   Setup parameter to decode pipeline
*   Initialize decoder
*   Decode frame by frame

![](images/psuedocode.png)
## Exploration
In this example we are decoding an AVC (H.264) stream.
*   Inclusions
*   Input Processing
*   Decoding pipeline
*   Output Processing
*   Main decoding loop
*   Error Handling
*   Finish decoding

## Observation

Observe different parameters of "sInputParams"

## Learning Outcome

By the end of this module, the participant is expected to understand the decoding an AVC (H.264) stream using Intel® Media SDK
## Open Visual Studio solution exercise

Please open empty solution from

**Desktop > Retail > 03-MediaSDK > lab\_exercise** folder

Open the **sample\_decode.sln** file located in sample\_decode folder

We have done all the necessary library linking in this solution.
## Inclusions
Open sample\_decode.cpp file to complete the exercise with the code given in the following steps:

Include the pipeline\_decode.h and sstream headers

```
        #include "pipeline_decode.h"
        #include <sstream>
  ```

## Input Processing
Define a method **InputSetup()** that accepts the sInputParams array defined from main program.

This method first checks the input array for consistency.

Then sets the video type, memory type, hardware acceleration, asynchronous depth factor, mode, etc.,

It also writes the input h264 file path to parameter list

Finally returns the MFX error status.

```
mfxStatus InputSetup(sInputParams* pParams)
                    {
                      //Check the pParams pointer
                      MSDK_CHECK_POINTER(pParams, MFX_ERR_NULL_PTR);

                      //Set the Video type:
                      //MFX_CODEC_AVC for H264 codec
                      //MFX_CODEC_JPEG for JPEG codec
                    	pParams->videoType = MFX_CODEC_AVC;

                    	msdk_opt_read(MSDK_STRING("C:\\input.h264"), pParams->strSrcFile);

                      //Set the memory type:
                      //D3D11_MEMORY for Directx11
                      //D3D9_MEMORY for Directx9
                      //SYSTEM_MEMORY for System Memory
                    	pParams->memType = D3D11_MEMORY;

                    	//set hardware implementation as default
                      //Software implementation can be tried by setting this to false.
                      pParams->bUseHWLib = true;

                      //Depth of asynchronous pipeline, this number can be tuned to achieve better performance.
                    	pParams->nAsyncDepth = 4;

                      //Set the eWorkMode from:
                      //MODE_PERFORMANCE,
                      //MODE_RENDERING,
                      //MODE_FILE_DUMP

                      pParams->mode = MODE_RENDERING;

                      //Some other parameters which can be explored further are:
                      /*bool    bIsMVC; // true if Multi-View Codec is in use
                        bool    bLowLat; // low latency mode
                        bool    bCalLat; // latency calculation
                        bool    bUseFullColorRange; //whether to use full color range
                        mfxU16  nMaxFPS; //rendering limited by certain fps
                        mfxU32  nWallCell;
                        mfxU32  nWallW; //number of windows located in each row
                        mfxU32  nWallH; //number of windows located in each column
                        mfxU32  nWallMonitor; //monitor id, 0,1,.. etc
                        bool    bWallNoTitle; //whether to show title for each window with fps value

                        mfxU32  numViews; // number of views for Multi-View Codec
                        mfxU32  nRotation; // rotation for Motion JPEG Codec
                        mfxU16  nAsyncDepth; // asyncronous queue
                        mfxU16  nTimeout; // timeout in seconds
                        mfxU16  gpuCopy; // GPU Copy mode (three-state option)
                      */

                      return MFX_ERR_NONE;
                    }

```

Declare the pipeline having input file reader, decoder and output file writer.

Then setup the input parameters and perform error checking.

Set the following parameters in the main program

```
                  // input parameters
                  sInputParams     Params;

                  // pipeline for decoding, includes input file reader, decoder and output file writer

                  CDecodingPipeline   Pipeline;

                  // return value check
                  mfxStatus sts = MFX_ERR_NONE;

                  //Setup your input parameters.
                  sts = InputSetup(&Params);

                  MSDK_CHECK_PARSE_RESULT(sts, MFX_ERR_NONE, 1);

```
## Decoding Pipeline

Initialise the decoding pipeline and check the error status.

Continue coding in the main program

```

         //Initialise the Decode pipeline

         sts = Pipeline.Init(&Params);

         MSDK_CHECK_RESULT(sts,MFX_ERR_NONE, 1);
```

## Output Processing

Print the stream information

Continue coding in the main program
```
    //print stream info
    Pipeline.PrintInfo();

    msdk_printf(MSDK_STRING("Decoding started\n"));


```
## Main Decoding Loop
Now let us loop all the frames in the video to decode them using **Pipeline.RunDecoding()**

Error handling for incompatible video parameters, lost device, failed device, etc.,

Reset the device using **Pipeline.ResetDevice** in case of hardaware error.

If there are no errors, it will set the flag to **MFX\_ERR\_NONE**

Finally clear all decode buffer and move to the next frame using **Pipeline.ResetDecoder(&Params);**

Continue following coding in the main function
```

            for (;;)
              {
               //Decode frame by frame
               sts = Pipeline.RunDecoding();

               if (MFX_ERR_INCOMPATIBLE_VIDEO_PARAM == sts || MFX_ERR_DEVICE_LOST == sts || MFX_ERR_DEVICE_FAILED == sts)
                {
                  if (MFX_ERR_INCOMPATIBLE_VIDEO_PARAM == sts)
                    {
                      msdk_printf(MSDK_STRING("\nERROR: Incompatible video parameters detected. Recovering...\n"));
                    }
                   else
                      {
                       msdk_printf(MSDK_STRING("\nERROR: Hardware device was lost or returned unexpected error. Recovering...\n"));

                        //Reset device in case of hardware error
                        sts = Pipeline.ResetDevice();

                        MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, 1);
                        }

                        //Clear all decode buffer and move to next frame.
                        sts = Pipeline.ResetDecoder(&Params);
                        MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, 1);
                        continue;
                        }
                    else
                      {
                        MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, 1);
                        break;
                        }
                    }

                  msdk_printf(MSDK_STRING("\nDecoding finished\n"));

```

**Build this solution for x64 in debug mode and run to see the output**
## Complete Solution
If you have problems in executing your code, you can see the complete Visual Studio solution in

**Desktop > Retail > 03-MediaSDK >complete\_solution** folder

We have done all the necessary library linking in this solution.
## Lesson learnt
Decoding the H.264 stream and exploring supported input parameters from Intel® Media SDK
