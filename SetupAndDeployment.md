# Setup Development Environment with the Intel® NUC7i7DNHE (Dawson Canyon)




## Lab Overview and Objectives


The labs in the Intel Visual Retail Workshop are organized in a progression that will result in each attendee building their own automated and secured, multi-device IoT network supporting Visual Retail scenarios.

Start by making sure your computer, is ready for Visual Retail development.

By the end of this module, you should be able to:

*   Unbox and setup your Intel®  Hardware
*   Connect to your Intel® NUC7i7DNHE (Dawson Canyon) to power and monitor.
*   Install Windows 10 Pro
*   Install Media Server Studio
*   Install OpenCV with Python support
*   Copy the required lab exercises

## Hardware Requirements

6th Generation Core Processor (Skylake)

1\. Unscrew the NUC7i7DNHE (Dawson Canyon) kit.

2\. Upgrade 1 DDR3 RAM in provided slot properly.

3\. Insert Solid state drive in the back case.

4\. Screw the NUC7i7DNHE (Dawson Canyon) kit.

5\. Power on the NUC7i7DNHE (Dawson Canyon) with Monitor connected.



## Software Requirements


## Manual Windows Configuration

1\. Power on the Intel NUC7i7DNHE (Dawson Canyon)

2\. Press F10 and boot from Windows 10 USB prepared using [Windows 10](\\10.224.54.1\Raghavendra\en_windows_10_multiple_editions_version_1607_updated_jul_2016_x64_dvd_9058187.iso)

3\. Install Windows 10.

4\. Set Username: intel and Password: intel123

5\. Download Workshop contents from [Workshop folder](\\10.224.54.1\Raghavendra\Bangalore-Workshop)

6\. Open the command prompt in admin mode and navigate to downloaded Workshop folder

7\. Goto 00-Installers, RunMe1.bat to install drivers. Don't restart in between.

8\. Reboot the system after RunMe1.bat finishes.

9\. Execute RunMe2.bat to install WindowsSDK, Directx 11 and [Visual Studio 10.](\\10.224.54.1\Raghavendra\en_visual_studio_2010_professional_x86_dvd_509727.iso)

Note:- Directx installation may ask for .NET framework 3.5 for which internet connection is a must.

10\. Execute RunMe3.bat to unmount the VS image, register Mars dlls, install opencv and Mesh commander.

11\. Copy folders 01 - 04 to Desktop > Retail

12\. Through elevated command prompt run Desktop > Retail > 01-MARS > filterDlls > regdll.bat, execute to register the dlls required for Mars

13\. Goto Desktop Retail > 01-Mars > Bin > Right Click on MARS.exe and Send to Desktop (create a link).



## Verification and Validation

1\. Run MARS.exe and check if one video is running properly.

2\. Run Python idle. Type: import cv2

3\. It should not give any error.

4\. Type: print cv2.\_\_version\_\_

5\. It should display the cv2 version

6\. Create System Restore point named "Retail".

7\. Shutdown the system, unplug the cables and stick Intel logo provided in the box, on to the NUC7i7DNHE (Dawson Canyon) and pack the box.

## Read about the next lab


Congratulations! You have successfully setup your Intel® NUC7i7DNHE (Dawson Canyon) with Windows for Visual Retail workshop. In the next section, you will learn how to enhance the video performance using Intel software.
