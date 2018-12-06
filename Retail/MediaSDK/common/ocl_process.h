/*****************************************************************************

INTEL CORPORATION PROPRIETARY INFORMATION
This software is supplied under the terms of a license agreement or
nondisclosure agreement with Intel Corporation and may not be copied
or disclosed except in accordance with the terms of that agreement.
Copyright(c) 2005-2014 Intel Corporation. All Rights Reserved.

*****************************************************************************/

#pragma once

#include <d3d9.h>
#include <cl/cl.h>
#include "mfxvideo++.h"

typedef struct _oclBuffers {
    cl_mem OCL_Y;
    cl_mem OCL_UV;
} OCLBuffers;

//
// Generic OpenCL processing class can used for both pre and post processing (incl. transcode)
//
class OCLProcess
{
public:
    OCLProcess();
    ~OCLProcess();

    // Create and setup components required for OpenCL processing
    cl_int OCLInit(IDirect3DDevice9Ex* pD3DDevice);

    // Setup shared OpenCL buffers
    cl_int OCLPrepare(int width,
                      int height,
                      mfxMemId* midsIn,
                      mfxU16 numSurfacesIn,
                      mfxMemId* midsOut,
                      mfxU16 numSurfacesOut);

    // Process a surface using OpenCL kernel
    cl_int OCLProcessSurface(int midIdxIn,
                             int midIdxOut,
                             cl_event* pclEventDone = NULL);

    // Release OpenCL resources
    void   OCLRelease();

protected:
    IDirect3DDevice9Ex* m_pD3DDevice;

    cl_platform_id      m_clPlatform;           // OpenCL platform
    cl_context          m_clContext;            // OpenCL context
    cl_command_queue    m_clQueue;              // OpenCL queue
    cl_program          m_clProgram;            // Compiled OpenCL program
    cl_kernel           m_clKernel;             // OpenCL kernel object
    cl_mem              m_oclSurfaces[4];       // Set of input and output Y/UV buffers to be acquired for OCL processing

    mfxMemId*           m_mids[2];              // Input and Output surface pointers
    mfxU16              m_numSurfaces[2];       // Number of Input and output surfaces
    OCLBuffers*         m_pOCLBuffers[2];       // Array of input and output OpenCL buffers for

    int                 m_frameSizeY[2];        // Y plane frame size
    int                 m_frameSizeUV[2];       // UV plane frame size
    size_t              m_GlobalWorkSizeUV[2];  // global sizes to process UV components
    size_t              m_LocalWorkSizeUV[2];   // local sizes to process UV components
    size_t              m_GlobalWorkSizeY[2];   // global sizes to process Y components
    size_t              m_LocalWorkSizeY[2];    // local sizes to process Y components
};










