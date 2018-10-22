# Setup Development Environment with the Intel® NUC 7i7DNHE (Dawson Canyon)




## Lab Overview and Objectives


The labs in the visual retail workshop are organized in a progression that will result in each attendee building their own automated and secured, multi-device IoT network supporting visual retail scenarios.

Start by making sure your computer is ready for visual retail development.

By the end of this module, you should be able to:

*   Unbox and setup your Intel® hardware
*   Connect to your Intel® NUC 7i7DNHE (Dawson Canyon) to power and monitor
*   Install Windows® 10 Pro
*   Install Media Server Studio
*   Install OpenCV with Python* support
*   Copy the required lab exercises

## Hardware Requirements

Intel® Core™ processor 6th Generation (Skylake)

1\. Unscrew the NUC 7i7DNHE (Dawson Canyon) kit.

2\. Upgrade 1 DDR3 RAM in provided slot properly.

3\. Insert solid state drive in the back case.

4\. Screw the Intel® NUC 7i7DNHE (Dawson Canyon) kit.

5\. Power on the Intel® NUC 7i7DNHE (Dawson Canyon) with Monitor connected.



## Software Requirements

There are two ways to configure Windows environment for the workshop, manual and automatic.



## Automatic Windows Configuration

1\. Automatic method involves the Windows* image created by Macrium Software and placed in [Visual Retail Windows Image](\\10.224.54.1\Raghavendra\Visual_Retail_Windows_Image)

Copy the above images in suitable storage device.

2\. Prepare a Resuce disk (USB) using the ISO provided in [Rescue ISO](\\10.224.54.1\Raghavendra\Rescue.iso) according to the instructions given in [Creating rescue media](https://knowledgebase.macrium.com/display/KNOW7/Creating+rescue+media)

3\. Boot through this rescue disk and restore the above mentioned Windows image using the instructions given in [Restoring a system image](https://knowledgebase.macrium.com/display/KNOW7/Restoring+a+system+image)

4\. On completion of system image restore, it asks to reboot, after which the Windows system will be ready for visual retail workshop

5\. Through elevated command prompt run Desktop > Retail > 01-MARS > filterDlls > regdll.bat, execute to register the dlls required for Mars

6\. Shutdown the system, unplug the cables, and stick the Intel logo provided in the box on to the Intel® NUC 7i7DNHE (Dawson Canyon) and pack the box.

Note:- [Windows Boot Troubleshoot](http://kb.macrium.com/KnowledgebaseArticle50168.aspx)



Note:-If the automatic configuration fails, you can try manual installation as follows

## Manual Windows Configuration

1\. Power on the Intel® NUC 7i7DNHE (Dawson Canyon)

2\. Press F10 and boot from Windows 10 USB prepared using [Windows 10](\\10.224.54.1\Raghavendra\en_windows_10_multiple_editions_version_1607_updated_jul_2016_x64_dvd_9058187.iso)

3\. Install Windows 10.

4\. Set Username: intel and Password: intel123

5\. Download workshop contents from [Workshop folder](\\10.224.54.1\Raghavendra\Bangalore-Workshop)

6\. Open the command prompt in admin mode and navigate to downloaded workshop folder

7\. Goto 00-Installers, RunMe1.bat to install drivers. Don't restart in between.

8\. Reboot the system after RunMe1.bat finishes.

9\. Execute RunMe2.bat to install WindowsSDK, DirectX* 11 and [Visual Studio 10.](\\10.224.54.1\Raghavendra\en_visual_studio_2010_professional_x86_dvd_509727.iso)

Note:- DirectX installation may ask for .NET framework 3.5 for which internet connection is a must.

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

7\. Shutdown the system, unplug the cables and stick Intel logo provided in the box, on to the Intel® NUC 7i7DNHE (Dawson Canyon) and pack the box.

## Read about the next lab


Congratulations! You have successfully setup your Intel® NUC 7i7DNHE (Dawson Canyon) with Windows for visual retail workshop. In the next section, you will learn how to enhance the video performance using Intel® software.
