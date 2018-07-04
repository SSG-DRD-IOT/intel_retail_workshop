/******************************************************************************\
Copyright (c) 2005-2016, Intel Corporation
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This sample was distributed or derived from the Intel's Media Samples package.
The original version of this sample may be obtained from
https://software.intel.com/en-us/intel-media-server-studio
or https://software.intel.com/en-us/media-client-solutions-support.
\**********************************************************************************/

#include "pipeline_decode.h"
#include <sstream>

mfxStatus InputSetup(sInputParams* pParams) {
  // Check the pParams pointer
  MSDK_CHECK_POINTER(pParams, MFX_ERR_NULL_PTR);

  // Set the Video type:
  // MFX_CODEC_AVC for H264 codec
  // MFX_CODEC_JPEG for JPEG codec
  pParams->videoType = MFX_CODEC_AVC;

  msdk_opt_read(MSDK_STRING("/home/intel[workshop id]/Documents/workshop/msdk_samples/samples/input.h264"),
                pParams->strSrcFile);

  // Set the memory type:
  // D3D11_MEMORY for Directx11
  // D3D9_MEMORY for Directx9
  // SYSTEM_MEMORY for System Memory
  pParams->memType = D3D9_MEMORY;

  // set hardware implementation as default
  // Software implementation can be tried by setting this to false.
  pParams->bUseHWLib = true;

  // Depth of asynchronous pipeline, this number can be tuned to achieve better
  // performance.
  pParams->nAsyncDepth = 4;

  // Set the eWorkMode from:
  // MODE_PERFORMANCE,
  // MODE_RENDERING,
  // MODE_FILE_DUMP

  pParams->mode = MODE_RENDERING;

  // pParams->libvaBackend = MFX_LIBVA_DRM;

  pParams->libvaBackend = MFX_LIBVA_X11;

  // Some other parameters which can be explored further are:
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

int main() {
  // input parameters
  sInputParams Params;

  // pipeline for decoding, includes input file reader, decoder and output file
  // writer
  CDecodingPipeline Pipeline;

  // return value check
  mfxStatus sts = MFX_ERR_NONE;

  // Setup your input parameters.
  sts = InputSetup(&Params);

  MSDK_CHECK_PARSE_RESULT(sts, MFX_ERR_NONE, 1);

  // Initialise the Decode pipeline

  sts = Pipeline.Init(&Params);

  MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, 1);

  // print stream info
  Pipeline.PrintInfo();

  msdk_printf(MSDK_STRING("Decoding started\n"));

  for (;;) {
    // Decode frame by frame
    sts = Pipeline.RunDecoding();

    if (MFX_ERR_INCOMPATIBLE_VIDEO_PARAM == sts || MFX_ERR_DEVICE_LOST == sts ||
        MFX_ERR_DEVICE_FAILED == sts) {
      if (MFX_ERR_INCOMPATIBLE_VIDEO_PARAM == sts) {
        msdk_printf(
            MSDK_STRING("\nERROR: Incompatible video parameters detected. "
                        "Recovering...\n"));
      } else {
        msdk_printf(
            MSDK_STRING("\nERROR: Hardware device was lost or returned "
                        "unexpected error. Recovering...\n"));

        // Reset device in case of hardware error
        sts = Pipeline.ResetDevice();

        MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, 1);
      }

      // Clear all decode buffer and move to next frame.
      sts = Pipeline.ResetDecoder(&Params);
      MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, 1);
      continue;
    } else {
      MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, 1);
      break;
    }
  }

  msdk_printf(MSDK_STRING("\nDecoding finished\n"));

  return 0;
}
