/*****************************************************************************

INTEL CORPORATION PROPRIETARY INFORMATION
This software is supplied under the terms of a license agreement or
nondisclosure agreement with Intel Corporation and may not be copied
or disclosed except in accordance with the terms of that agreement.
Copyright(c) 2005-2014 Intel Corporation. All Rights Reserved.

*****************************************************************************/

#include "common_utils.h"
#include <iostream>

int main()
{
	mfxStatus sts = MFX_ERR_NONE;

	// =====================================================================
	// Intel Media SDK decode pipeline setup
	//


	//1. Open input file
	FILE* fSource;
#if defined(_WIN32) || defined(_WIN64)
    char path[] = "..\\bbb_sunflower_2160p_30fps_normal.h264";
#elif defined(__linux__)
    char path[] = "../bbb_sunflower_2160p_30fps_normal.h264";
#endif
	MSDK_FOPEN(fSource, path, "rb");
	MSDK_CHECK_POINTER(fSource, MFX_ERR_NULL_PTR);

	//2. Initialize Intel Media SDK session
	// - Version 1.0 is selected for greatest backwards compatibility.
	mfxIMPL impl = MFX_IMPL_SOFTWARE;
	mfxVersion ver = { {0, 1} };
	MFXVideoSession session;

	sts = Initialize(impl, ver, &session, NULL);
	MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, sts);

	// Create Media SDK decoder
	MFXVideoDECODE mfxDEC(session);

	//3. Set required video parameters for decode
	mfxVideoParam mfxVideoParams;
	memset(&mfxVideoParams, 0, sizeof(mfxVideoParams));
	mfxVideoParams.mfx.CodecId = MFX_CODEC_AVC;
	mfxVideoParams.IOPattern = MFX_IOPATTERN_OUT_SYSTEM_MEMORY;

	//4. Prepare Media SDK bit stream buffer
	// - Arbitrary buffer size for this example
	mfxBitstream mfxBS;
	memset(&mfxBS, 0, sizeof(mfxBS));
	mfxBS.MaxLength = 1024 * 1024;
	mfxBS.Data = new mfxU8[mfxBS.MaxLength];
	MSDK_CHECK_POINTER(mfxBS.Data, MFX_ERR_MEMORY_ALLOC);

	// Read a chunk of data from stream file into bit stream buffer
	// - Parse bit stream, searching for header and fill video parameters structure
	// - Abort if bit stream header is not found in the first bit stream buffer chunk
	sts = ReadBitStreamData(&mfxBS, fSource);
	MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, sts);

	sts = mfxDEC.DecodeHeader(&mfxBS, &mfxVideoParams);
	MSDK_IGNORE_MFX_STS(sts, MFX_WRN_PARTIAL_ACCELERATION);
	MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, sts);

	// Validate video decode parameters (optional, but recommended)
	 sts = mfxDEC.Query(&mfxVideoParams, &mfxVideoParams);

	// Query number of required surfaces for decoder
	mfxFrameAllocRequest Request;
	memset(&Request, 0, sizeof(Request));
	sts = mfxDEC.QueryIOSurf(&mfxVideoParams, &Request);
	MSDK_IGNORE_MFX_STS(sts, MFX_WRN_PARTIAL_ACCELERATION);
	MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, sts);

	mfxU16 numSurfaces = Request.NumFrameSuggested;

	//5. Allocate surfaces for decoder
	// - Width and height of buffer must be aligned, a multiple of 32
	// - Frame surface array keeps pointers to all surface planes and general frame info
	mfxU16 width = (mfxU16) MSDK_ALIGN32(Request.Info.Width);
	mfxU16 height = (mfxU16) MSDK_ALIGN32(Request.Info.Height);
	mfxU8 bitsPerPixel = 12;        // NV12 format is a 12 bits per pixel format
	mfxU32 surfaceSize = width * height * bitsPerPixel / 8;
	mfxU8* surfaceBuffers = (mfxU8*) new mfxU8[surfaceSize * numSurfaces];

	// Allocate surface headers (mfxFrameSurface1) for decoder
	mfxFrameSurface1** pmfxSurfaces = new mfxFrameSurface1 *[numSurfaces];
	MSDK_CHECK_POINTER(pmfxSurfaces, MFX_ERR_MEMORY_ALLOC);
	for (int i = 0; i < numSurfaces; i++) {
		pmfxSurfaces[i] = new mfxFrameSurface1;
		memset(pmfxSurfaces[i], 0, sizeof(mfxFrameSurface1));
		memcpy(&(pmfxSurfaces[i]->Info), &(mfxVideoParams.mfx.FrameInfo), sizeof(mfxFrameInfo));
		pmfxSurfaces[i]->Data.Y = &surfaceBuffers[surfaceSize * i];
		pmfxSurfaces[i]->Data.U = pmfxSurfaces[i]->Data.Y + width * height;
		pmfxSurfaces[i]->Data.V = pmfxSurfaces[i]->Data.U + 1;
		pmfxSurfaces[i]->Data.Pitch = width;
	}

	//6. Initialize the Media SDK decoder
	sts = mfxDEC.Init(&mfxVideoParams);
	MSDK_IGNORE_MFX_STS(sts, MFX_WRN_PARTIAL_ACCELERATION);
	MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, sts);

	// ===============================================================
	// Start decoding the frames
	//

	mfxTime tStart, tEnd;
	mfxGetTime(&tStart);

	mfxSyncPoint syncp;
	mfxFrameSurface1* pmfxOutSurface = NULL;
	int nIndex = 0;
	mfxU32 nFrame = 0;

	//
	// Stage 1: Main decoding loop
	//
	while (MFX_ERR_NONE <= sts || MFX_ERR_MORE_DATA == sts || MFX_ERR_MORE_SURFACE == sts) {
		if (MFX_WRN_DEVICE_BUSY == sts)
			MSDK_SLEEP(1);  // Wait if device is busy, then repeat the same call to DecodeFrameAsync

		if (MFX_ERR_MORE_DATA == sts) {
			sts = ReadBitStreamData(&mfxBS, fSource);       // Read more data into input bit stream
			MSDK_BREAK_ON_ERROR(sts);
		}

		if (MFX_ERR_MORE_SURFACE == sts || MFX_ERR_NONE == sts) {
			nIndex = GetFreeSurfaceIndex(pmfxSurfaces, numSurfaces);        // Find free frame surface
			MSDK_CHECK_ERROR(MFX_ERR_NOT_FOUND, nIndex, MFX_ERR_MEMORY_ALLOC);
		}
		// Decode a frame asychronously (returns immediately)
		//  - If input bitstream contains multiple frames DecodeFrameAsync will start decoding multiple frames, and remove them from bitstream
		sts = mfxDEC.DecodeFrameAsync(&mfxBS, pmfxSurfaces[nIndex], &pmfxOutSurface, &syncp);

		// Ignore warnings if output is available,
		// if no output and no action required just repeat the DecodeFrameAsync call
		if (MFX_ERR_NONE < sts && syncp)
			sts = MFX_ERR_NONE;

		if (MFX_ERR_NONE == sts)
			sts = session.SyncOperation(syncp, 60000);      // Synchronize. Wait until decoded frame is ready

		if (MFX_ERR_NONE == sts) {
			++nFrame;

			if (nFrame % 100 == 0) {
				printf("Frame number: %d\r", nFrame);
				fflush(stdout);
			}
		}
	}

	// MFX_ERR_MORE_DATA means that file has ended, need to go to buffering loop, exit in case of other errors
	MSDK_IGNORE_MFX_STS(sts, MFX_ERR_MORE_DATA);
	MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, sts);

	//
	// Stage 2: Retrieve the buffered decoded frames
	//
	while (MFX_ERR_NONE <= sts || MFX_ERR_MORE_SURFACE == sts) {
		if (MFX_WRN_DEVICE_BUSY == sts)
			MSDK_SLEEP(1);  // Wait if device is busy, then repeat the same call to DecodeFrameAsync

		nIndex = GetFreeSurfaceIndex(pmfxSurfaces, numSurfaces);        // Find free frame surface
		MSDK_CHECK_ERROR(MFX_ERR_NOT_FOUND, nIndex, MFX_ERR_MEMORY_ALLOC);

		// Decode a frame asychronously (returns immediately)
		sts = mfxDEC.DecodeFrameAsync(NULL, pmfxSurfaces[nIndex], &pmfxOutSurface, &syncp);

		// Ignore warnings if output is available,
		// if no output and no action required just repeat the DecodeFrameAsync call
		if (MFX_ERR_NONE < sts && syncp)
			sts = MFX_ERR_NONE;

		if (MFX_ERR_NONE == sts)
			sts = session.SyncOperation(syncp, 60000);      // Synchronize. Waits until decoded frame is ready

		if (MFX_ERR_NONE == sts) {
			++nFrame;
			printf("Frame number: %d\r", nFrame);
			fflush(stdout);
		}
	}

	// MFX_ERR_MORE_DATA indicates that all buffers has been fetched, exit in case of other errors
	MSDK_IGNORE_MFX_STS(sts, MFX_ERR_MORE_DATA);
	MSDK_CHECK_RESULT(sts, MFX_ERR_NONE, sts);

	mfxGetTime(&tEnd);
	double elapsed = TimeDiffMsec(tEnd, tStart) / 1000;
	double fps = ((double)nFrame / elapsed);
	printf("\nExecution time: %3.2f s (%3.2f fps)\n", elapsed, fps);

	// ===================================================================
	// 8. Clean up resources
	//  - It is recommended to close Media SDK components first, before releasing allocated surfaces, since
	//    some surfaces may still be locked by internal Media SDK resources.

	mfxDEC.Close();
	// session closed automatically on destruction

	for (int i = 0; i < numSurfaces; i++)
		delete pmfxSurfaces[i];
	MSDK_SAFE_DELETE_ARRAY(pmfxSurfaces);
	MSDK_SAFE_DELETE_ARRAY(mfxBS.Data);

	MSDK_SAFE_DELETE_ARRAY(surfaceBuffers);

	fclose(fSource);

	Release();

	std::cout << "Press ENTER to exit...";
	std::cin.get();

	return 0;
}
