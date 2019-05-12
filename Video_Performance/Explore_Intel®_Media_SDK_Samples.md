# Explore Intel® Media SDK Samples
## Introduction

Intel® Media SDK is a set of libraries, tools, header and sample code files that define cross-platform API for developing consumer and professional grade media applications on Intel platforms. Providing an access to Intel® Quick Sync Video, hardware accelerated codecs in Intel Graphics Processor, Media SDK allows application developer to speed up video playback, encoding, processing and media conversion. Media SDK for Windows helps to deliver desktop applications, such as video players, editors and video conferencing clients, while Media SDK for Embedded Linux enables digital security and surveillance and connected car manufacturers to deliver smart cameras and infotainment or cluster display solutions.

## Exploration

This lab starts with exploring and understanding the media sdk related packages installed in your Intel® NUC7i7DNHE (Dawson Canyon). Then understand the customized applications such as sample decoder and video wall bundled with installation.

## Observation

Performance monitoring using system performance monitoring tool; before and after hardware acceleration.

## Learning Outcome

By the end of this module, the participant is expected to understand the Intel® Media SDK, installation structure, hardware acceleration and performance enhancement of selected applications.
## View the packages installed on your NUC7i7DNHE (Dawson Canyon)

-  **Media SDK installer**

    MSDK2018R2.exe by default installs at C:\Program Files (x86)\IntelSWTools\Intel(R) Media SDK 2018 R2

-  **Media Sample applications**

    Media SDK samples is made available in C:\Users\user_name\Documents\Intel® Media SDK 2018 R2-Media Samples 8.4.27.378
- **Media SDK Documentation directory**

    C:\Program Files (x86)\IntelSWTools\Intel(R) Media SDK 2018 R2\Software Development kit\doc

## Understand the packages

1. **Click the File Explorer shortcut on the taskbar**
2. **Navigate to C:\Program Files (x86)\IntelSWTools\Intel(R) Media SDK 2018 R2\Software Development kit**

![Media SDK directory contents](images/Packages.JPG)

*   **bin** folder has 32-bit and 64-bit runtime libraries for audio and media function encode-decode software capabilities.

    E.g., _libmfxsw32.dll_ is the software library for IA-32 architecture

    _libmfxsw64.dll_ is the software library for Intel® 64 architecture

*   **doc** folder has documentation for raw, audio, image, video, etc., media types. It also provide media sdk user manual and developer reference manuals

*   **include** folder has several header files supporting Intel® media sdk program development

*   **lib** folder has 32-bit and 64-bit static library _libmfx.lib_ for media function encoding and decoding

    It also may have _libmfx\_vs2015.lib_ to link Intel® Media SDK with MS® Visual Studio 2015

*   **open source** folder has SDK dispatcher. The dispatcher is a layer that lies between applications and SDK implementations. Upon initialization, the dispatcher locates the appropriate platform-specific SDK implementation. If there is none, it will select the software SDK implementation. The dispatcher will redirect subsequent function calls to the same functions in the selected SDK implementation.

*   **tools** folder has MediaSDK Tracer and Mediasdk System Analyzer - 64-bit and 32-bit supported.

## 1. MediaSDK Tracer:

  This tool will capture the basic call information from Media SDK API functions. It will generate a full log of interaction between the application and the SDK library including per-frame processing.

  **Note:** We are not running this tool in the workshop. For more infromation please refer to the readme-mediasdk-tracer document (C:\Program Files (x86)\IntelSWTools\Intel(R) Media SDK 2018 R2\Software Development Kit\tools\mediasdk_tracer) to know the system requirements and limitations of the tool.

## 2. MediaSDK System Analyzer:

  This tool utility analyzes the system and reports all Media SDK related capabilities, driver and components status. This tool can also be used to determine setup environment issues. This tool reports back installed graphics adapter, basic system information, installed Media SDK versions, installed DirectShow filters, Media foundation Transforms (MFT) and also tips for solutions in case either software or hardware implementations did not work.

  1. **Navigate to the MediaSDK System Analyzer folder using the File Explorer:
  C:\Program Files (x86)\IntelSWTools\Intel(R) Media SDK 2018 R2\Software Development Kit\tools\mediasdk_sys_analyzer**
  2. **Double click mediasdk_system_analyzer_64.exe**

  Usage:

  This tool starts reporting system status immediately. The tool will show you information about your system and what Media SDK packages are installed. **When complete, a user can exit the tool by pressing ENTER key.**

  **Note:** For more information please refer to the document (readme-mediasdk-system-analyzer.rtf) to know the system requirements and limitations of the system analyzer.

  Example Output:

  ![](images/SystemAnalyzer.JPG)
  ## 1. Sample Decoder
  
  1. **Type *command prompt* in the search box on the taskbar.**
  2. **Click the *Command Prompt* result**
  3. **Navigate to the Desktop > Retail > 03-MediaSDK > folder in your command prompt window:**
  
  ```
  cd C:\Users\intel\Desktop\Retail\03-MediaSDK
  ```
  
  4. **Right click the taskbar and click Task Manager in the context menu**
  5. **Click More details in the bottom left corner of the Task Manager window to access advanced mode**
  6. **Click the Performance tab to compare the CPU performance of the below two cases.**

   **Note:** If you are running any other programs, their process will be added to the CPU & memory utilization. So try closing all other programs. Then observe the Sample_decode.exe process performance from task manager.

### Case 1: Software implementation:
  1. **Execute the following command in the Command Prompt window**
```
sample_decode.exe h264 -i input.h264 -sw
```

Output & Performance:

![](images/MSDK_SW.jpg)  


### Case 2: Hardware acceleration:
1. **Execute the following command in the Command Prompt window**
```
sample_decode.exe h264 -i input.h264 -hw
```

Output & Performance:

![](images/MSDK_HW.jpg)  


2. **Type *sample_decode.exe* in the Command Prompt window to view the command line arguments:**
*Some of the available arguments*
```
...
\-o : output to file in RAW formats  
\-r: Present  
\-f : change rendering frame rate  
\-w and –h : changing the resolution
...
```

3. **Execute the following command in the Command Prompt window to run the video wall sample application with the provided video file**
```
sample_video_wall.bat input.h264
```

4. **Observe the video projected on the video wall divided into multiple channels as specified in the batch file**

5. **Type *wordpad* in the search box on the taskbar.**
6. **Click the *WordPad* result**
7. **Click File tab > Open**
8. **Navigate to C:\Users\intel\Desktop\Retail\03-MediaSDK in the Open window**
9. **Select *All Documents (\*.\*)* in the File type dropdown**
10. **Select and Open sample_video_wall.bat**
11. **Replace the VerticalCells and HorizontalCells lines to change the channel configuration of the video wall with the following lines:**
```
set VerticalCells=3
set HorizontalCells=3
```
12. **Press the ENTER key to get the cursor back**
13. **Execute the command below to view the new channel configuration**
```
sample_video_wall.bat input.h264
```

14. [Optional] **Replace the MediaSDKImplementation line with the following to execute the software implementation:**
```
set MediaSDKImplementation=-sw
```

## Lessons learnt
*   Intel® Media SDK's libraries, tools, header and sample code files.
*   speed up in video playback, encoding, processing and media conversion.
*   Performance monitoring

