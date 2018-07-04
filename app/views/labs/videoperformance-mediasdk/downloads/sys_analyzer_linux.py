#!/usr/bin/python
"""

Copyright (c) 2017 Intel Corporation All Rights Reserved.

THESE MATERIALS ARE PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL INTEL OR ITS
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THESE
MATERIALS, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

File Name: sys_analyzer.py

Abstract: Script for checking the environment for Intel Media Server Studio
Media SDK and SDK for OpenCL Applications install and run readiness

Notes: Run sys_analyzer.py

"""

import os, sys, platform
import os.path

class diagnostic_colors:
    ERROR   = '\x1b[31;1m'  # Red/bold
    SUCCESS = '\x1b[32;1m'  # green/bold
    RESET   = '\x1b[0m'     # Reset attributes
    INFO    = '\x1b[34;1m'  # info
    OUTPUT  = ''            # command's coutput printing
    STDERR  = '\x1b[36;1m'  # cyan/bold
    SKIPPED = '\x1b[33;1m'  # yellow/bold

class loglevelcode:
    ERROR   = 0
    SUCCESS = 1
    INFO    = 2

GLOBAL_LOGLEVEL=1

def print_info( msg, loglevel ):
    global GLOBAL_LOGLEVEL

    """ printing information """    
    
    if loglevel==loglevelcode.ERROR and GLOBAL_LOGLEVEL>=0:
        color = diagnostic_colors.ERROR
        msgtype=" [ ERROR ] "
        print( color + msgtype + diagnostic_colors.RESET + msg )
    elif loglevel==loglevelcode.SUCCESS and GLOBAL_LOGLEVEL>=1:
        color = diagnostic_colors.SUCCESS
        msgtype=" [ OK ] "
        print( color + msgtype + diagnostic_colors.RESET + msg )
    elif loglevel==loglevelcode.INFO and GLOBAL_LOGLEVEL>=2:
        color = diagnostic_colors.INFO
        msgtype=" [ INFO ] "
        print( color + msgtype + diagnostic_colors.RESET + msg )


    
    return

def run_cmd(cmd):
    output=""
    fin=os.popen(cmd+" 2>&1","r")
    for line in fin:
        output+=line
    fin.close()
    return output

def find_library(libfile):
    search_path=os.environ.get("LD_LIBRARY_PATH","/usr/lib64")
    if not ('/usr/lib64' in search_path):
	search_path+=";/usr/lib64"
    paths=search_path.split(";")

    found=False
    for libpath in paths:
        if os.path.exists(libpath+"/"+libfile):
            found=True
            break
    
    return found


def parse_pciid(pciid):
    sts=loglevelcode.ERROR
    gpustr="unknown"

    id_directory={
    '0402':'HSW GT1 desktop',
    '0412':'HSW GT2 desktop',
    '0422':'HSW GT3 desktop',
    '040a':'HSW GT1 server',
    '041a':'HSW GT2 server',
    '042a':'HSW GT3 server',
    '040B':'HSW GT1 reserved',
    '041B':'HSW GT2 reserved',
    '042B':'HSW GT3 reserved',
    '040E':'HSW GT1 reserved',
    '041E':'HSW GT2 reserved',
    '042E':'HSW GT3 reserved',
    '0C02':'HSW SDV GT1 desktop',
    '0C12':'HSW SDV GT2 desktop',
    '0C22':'HSW SDV GT3 desktop',
    '0C0A':'HSW SDV GT1 server',
    '0C1A':'HSW SDV GT2 server',
    '0C2A':'HSW SDV GT3 server',
    '0C0B':'HSW SDV GT1 reserved',
    '0C1B':'HSW SDV GT2 reserved',
    '0C2B':'HSW SDV GT3 reserved',
    '0C0E':'HSW SDV GT1 reserved',
    '0C1E':'HSW SDV GT2 reserved',
    '0C2E':'HSW SDV GT3 reserved',
    '0A02':'HSW ULT GT1 desktop',
    '0A12':'HSW ULT GT2 desktop',
    '0A22':'HSW ULT GT3 desktop',
    '0A0A':'HSW ULT GT1 server',
    '0A1A':'HSW ULT GT2 server',
    '0A2A':'HSW ULT GT3 server',
    '0A0B':'HSW ULT GT1 reserved',
    '0A1B':'HSW ULT GT2 reserved',
    '0A2B':'HSW ULT GT3 reserved',
    '0D02':'HSW CRW GT1 desktop',
    '0D12':'HSW CRW GT2 desktop',
    '0D22':'HSW CRW GT3 desktop',
    '0D0A':'HSW CRW GT1 server',
    '0D1A':'HSW CRW GT2 server',
    '0D2A':'HSW CRW GT3 server',
    '0D0B':'HSW CRW GT1 reserved',
    '0D1B':'HSW CRW GT2 reserved',
    '0D2B':'HSW CRW GT3 reserved',
    '0D0E':'HSW CRW GT1 reserved',
    '0D1E':'HSW CRW GT2 reserved',
    '0D2E':'HSW CRW GT3 reserved',
    '0406':'HSW GT1 mobile',
    '0416':'HSW GT2 mobile',
    '0426':'HSW GT2 mobile',
    '0C06':'HSW SDV GT1 mobile',
    '0C16':'HSW SDV GT2 mobile',
    '0C26':'HSW SDV GT3 mobile',
    '0A06':'HSW ULT GT1 mobile',
    '0A16':'HSW ULT GT2 mobile',
    '0A26':'HSW ULT GT3 mobile',
    '0A0E':'HSW ULX GT1 mobile',
    '0A1E':'HSW ULX GT2 mobile',
    '0A2E':'HSW ULT GT3 reserved',
    '0D06':'HSW CRW GT1 mobile',
    '0D16':'HSW CRW GT2 mobile',
    '0D26':'HSW CRW GT3 mobile',
    '1602':'BDW GT1 ULT',
    '1606':'BDW GT1 ULT',
    '160B':'BDW GT1 Iris',
    '160E':'BDW GT1 ULX',
    '1612':'BDW GT2 Halo',
    '1616':'BDW GT2 ULT',
    '161B':'BDW GT2 ULT',
    '161E':'BDW GT2 ULX',
    '160A':'BDW GT1 Server',
    '160D':'BDW GT1 Workstation',
    '161A':'BDW GT2 Server',
    '161D':'BDW GT2 Workstation',
    '1622':'BDW GT3 ULT',
    '1626':'BDW GT3 ULT',
    '162B':'BDW GT3 Iris',
    '162E':'BDW GT3 ULX',
    '162A':'BDW GT3 Server',
    '162D':'BDW GT3 Workstation',
    '1632':'BDW RSVD ULT',
    '1636':'BDW RSVD ULT',
    '163B':'BDW RSVD Iris',
    '163E':'BDW RSVD ULX',
    '163A':'BDW RSVD Server',
    '163D':'BDW RSVD Workstation',
    '1906':'SKL ULT GT1',
    '190E':'SKL ULX GT1',
    '1902':'SKL DT GT1',
    '190B':'SKL Halo GT1',
    '190A':'SKL SRV GT1',
    '1916':'SKL ULT GT2',
    '1921':'SKL ULT GT2F',
    '191E':'SKL ULX GT2',
    '1912':'SKL DT GT2',
    '191B':'SKL Halo GT2',
    '191A':'SKL SRV GT2',
    '191D':'SKL WKS GT2',
    '1923':'SKL ULT GT3',
    '1926':'SKL ULT GT3',
    '1927':'SKL ULT GT3',
    '192B':'SKL Halo GT3',
    '192D':'SKL SRV GT3',
    '1932':'SKL DT GT4',
    '193B':'SKL Halo GT4',
    '193D':'SKL WKS GT4',
    '192A':'SKL SRV GT4',
    '193A':'SKL SRV GT4e',
    '5A84':'APL HD Graphics 505',
    '5A85':'APL HD Graphics 500',
    '5913':'KBL ULT GT1.5',
    '5915':'KBL ULX GT1.5',
    '5917':'KBL DT GT1.5',
    '5906':'KBL ULT GT1',
    '590E':'KBL ULX GT1',
    '5902':'KBL DT GT1',
    '5908':'KBL Halo GT1',
    '590B':'KBL Halo GT1',
    '590A':'KBL SRV GT1',
    '5916':'KBL ULT GT2',
    '5921':'KBL ULT GT2F',
    '591E':'KBL ULX GT2',
    '5912':'KBL DT GT2',
    '591B':'KBL Halo GT2',
    '591A':'KBL SRV GT2',
    '591D':'KBL WKS GT2',
    '5923':'KBL ULT GT3',
    '5926':'KBL ULT GT3',
    '5927':'KBL ULT GT3',
    '593B':'KBL Halo GT4'}


    try:
        gpustr=id_directory[pciid]
        sts=loglevelcode.SUCCESS
    except:
        pass

    return (sts,gpustr)

def get_processor():
    processor_name="unknown"
    f=open("/proc/cpuinfo","r")
    for line in f:
        if line.find("model name")<0: continue
        line=line.strip()
        (var,val)=line.split(":")
        processor_name=val
        break

    return processor_name.strip()



def does_processor_have_gen_graphics():
    processor_name=get_processor()
    print_info("Processor name: "+processor_name,loglevelcode.SUCCESS)
    processor_name=processor_name.upper()	


    if (processor_name.find("INTEL")>=0):
        print_info("Intel Processor",loglevelcode.INFO) 
    else:
        print_info("Not an Intel processor.  No Media GPU capabilities supported.",loglevelcode.ERROR)


    if (processor_name.find("CORE")>=0):
        print_info("Processor brand: Core",loglevelcode.INFO)

        pos=-1
        pos=processor_name.find("I7-")
        if (pos<0): pos=processor_name.find("I5-")
        if (pos<0): pos=processor_name.find("I3-")

        core_vnum=processor_name[pos+3:pos+7]
        try:
            procnum=int(core_vnum)
            archnum=procnum/1000
            if (archnum==4):
		print_info("Processor arch: Haswell",loglevelcode.INFO)
            elif (archnum==5):
		print_info("Processor arch: Broadwell",loglevelcode.INFO)
            elif (archnum==6): 
                print_info("Processor arch: Skylake",loglevelcode.INFO)
        except:
            pass
        

    elif (processor_name.find("XEON")>=0):
	print_info("Processor brand: Xeon",loglevelcode.INFO)
        pos=processor_name.find(" V")
        if pos>0:
	    xeon_vnum=processor_name[pos+1:pos+3]
	    if ("V3" in xeon_vnum):
		print_info("Processor arch: Haswell",loglevelcode.INFO)
            elif ("V4" in xeon_vnum):
		print_info("Processor arch: Broadwell",loglevelcode.INFO)
            elif ("V5" in xeon_vnum): 
                print_info("Processor arch: Skylake",loglevelcode.INFO)

    else:
        print_info("Processor not Xeon or Core.  Not supported.",loglevelcode.ERROR)
    
   

    return loglevelcode.SUCCESS
 
def is_OS_media_ready():

    #check GPU PCIid
    lspci_output=run_cmd("lspci -nn -s 0:02.0")
    pos=lspci_output.rfind("[8086:")
    pciid=lspci_output[pos+6:pos+10].upper()
    (sts,gpustr)=parse_pciid(pciid)
    print_info("GPU PCI id     : " +pciid,loglevelcode.INFO)
    print_info("GPU description: "+gpustr,loglevelcode.INFO)
    if sts==loglevelcode.SUCCESS:
        print_info("GPU visible to OS",loglevelcode.SUCCESS)
    else:
        print_info("No compatible GPU available.  Check BIOS settings?",loglevelcode.INFO)
        return loglevelcode.INFO

    #check for nomodeset
    grub_cmdline_output=run_cmd("cat /proc/cmdline")
    if (grub_cmdline_output.find("nomodeset")>0):
        print_info("nomodeset detected in GRUB cmdline",loglevelcode.ERROR)
        return loglevelcode.ERROR
    else:
        print_info("no nomodeset in GRUB cmdline (good)",loglevelcode.INFO)
        

    #Linux distro
    (linux_distro_name,linux_distro_version,linux_distro_details)=platform.linux_distribution()
    linux_distro=linux_distro_name+" "+linux_distro_version
    print_info("Linux distro   : "+linux_distro,loglevelcode.INFO)

    #kernel
    uname_output=run_cmd("uname -r")
    print_info("Linux kernel   : "+uname_output.strip(),loglevelcode.INFO)

    #glibc version
    ldd_version_output=run_cmd("ldd --version")
    pos=ldd_version_output.find("Copyright")
    ldd_version_output=ldd_version_output[0:pos-1]
    tmp=ldd_version_output.split()

    try:
        ldd_version=float(tmp.pop())
    except:
        ldd_version=0

    if (ldd_version>=2.12):
        outstr="glibc version  : %4.2f"%(ldd_version)
        print_info(outstr,loglevelcode.INFO)
    else:
        outstr="glibc version  : %4.2f >= 2.12 required!"%(ldd_version)
        print_info(outstr,loglevelcode.ERROR)
        return loglevelcode.ERROR

 
    
    if (linux_distro.find("CentOS Linux 7.1.1503")>=0):
        print_info("Linux distro suitable for Media Server Studio 2016 Gold",loglevelcode.SUCCESS)
    else:
        print_info("Linux distro suitable for Generic install",loglevelcode.INFO)



    #gcc version
    gcc_version_output=run_cmd("gcc --version")
    if ("not found" in gcc_version_output):
	print_info("gcc not found",loglevelcode.ERROR)
	sys.exit(1)
    else:
    	pos=gcc_version_output.find("Copyright")
    	gcc_version_output=gcc_version_output[0:pos-1]
    	tmp=gcc_version_output.split()    
    	gcc_version=tmp.pop()
    	print_info("gcc version    : "+gcc_version + " (>=4.8.2 suggested)",loglevelcode.INFO)


    return loglevelcode.SUCCESS

def check_libdrm():
    codestr="""#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "xf86drm.h"
#include <fcntl.h>
#include <unistd.h>
#include <va/va.h>
#include <va/va_drm.h>
int main(int argc,char **argv)
{

  int devices_found=0;

  // VAAPI display handle
  VADisplay va_dpy=NULL;
  VAStatus va_res = VA_STATUS_SUCCESS;
  int major_version = 0, minor_version = 0;
  int fd=-1;
  drmVersionPtr pDRMVersionInfo=NULL;


  //search for valid graphics device
  

    char adapterpath[256];
    char drivername[256];

    snprintf(adapterpath,sizeof(adapterpath),"%s",argv[1]);

    printf("trying %s\\n",adapterpath);

    fd = open(adapterpath, O_RDWR);

    
    if (fd < 0) {
      printf("could not open %s\\n",adapterpath);
      return -1;
    }

    va_dpy = vaGetDisplayDRM(fd);

    if (!va_dpy) {
      printf("could get display DRM for %s\\n",adapterpath);
      close(fd);
      return -2;
    }

    //get driver corresponding to this adapter
    pDRMVersionInfo=drmGetVersion(fd);
    strncpy (drivername, pDRMVersionInfo->name, sizeof(drivername) );
    drmFreeVersion(pDRMVersionInfo);

    printf("%s driver=%s ",adapterpath,drivername);

    if (strncmp(drivername,"i915",4)!=0)
      {
	printf("Non-Intel driver\\n");
	close(fd);
	fd = -1;
	return -4;
      }

    va_res = vaInitialize(va_dpy, &major_version, &minor_version);

    if (VA_STATUS_SUCCESS != va_res) {
      printf("vaInitialize failed\\n");
      close(fd);
      fd = -1;
      return -5;
    }
    else
      {
	printf("Intel driver OK\\n");
	devices_found++;
      }
  

  if (devices_found==0) puts("NO DEVICES FOUND!");
  else printf("devices found: %d\\n",devices_found);

}
"""
    if not os.path.exists("/usr/include/xf86drm.h"):
        print_info("no libdrm include files. Are Intel components installed?",loglevelcode.ERROR)
        return

    if not os.path.exists("/usr/include/va/va.h"):
        print_info("no libva include files.  Are Intel components installed?",loglevelcode.ERROR)
        return

    f=open("drmcheck_tmp.c","w")
    f.write(codestr)
    f.close()

    cmd="g++ -o drmcheck drmcheck_tmp.c -I/usr/include/libdrm -lva -lva-drm -ldl -ldrm "
    sts=os.system(cmd)
    if not sts==0:
        print_info("libdrm check failed. Are Intel components installed?",loglevelcode.ERROR)
        
    if os.path.exists("/dev/dri/renderD128"):
        f=os.popen("ls -1 /dev/dri/renderD*")
        for line in f:
            interface_str=line.strip()
            drmsts=os.system("./drmcheck %s >/dev/null 2>&1"%(interface_str))
            if drmsts==0:
                print_info(interface_str+" connects to Intel i915",loglevelcode.SUCCESS)
            else:
                print_info("could not open "+interface_str,loglevelcode.ERROR)
    else:
        print_info("no /dev/dri/renderD* interfaces found",loglevelcode.ERROR)

    os.remove("drmcheck")
    os.remove("drmcheck_tmp.c")


def check_msdk_api():
    codestr="""
#include <mfxvideo.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
int main(int argc, char **argv)
{
    mfxVersion ver = { {0, 1} };
    mfxSession session;
    if (argc<2) return 0;
    if (strncmp(argv[1],"HW",2)==0) {
       MFXInit(MFX_IMPL_HARDWARE_ANY,&ver,&session);
    } else {
        MFXInit(MFX_IMPL_SOFTWARE,&ver,&session);
    }
    MFXQueryVersion(session,&ver);
    printf("%d.%d\\n",ver.Major,ver.Minor);
    return 0;
}
"""

    if not os.path.exists("/opt/intel/mediasdk/include/mfxvideo.h"):
        print_info("no Media SDK include files.  Are Intel components installed?",loglevelcode.ERROR)
        return

    if not find_library("libva.so"):
        print_info("no libva.so.  Are Intel components installed?",loglevelcode.ERROR)
        return        

    if not find_library("libdrm.so"):
        print_info("no libdrm.so.  Are Intel components installed?",loglevelcode.ERROR)
        return        

    f=open("msdkcheck_tmp.c","w")
    f.write(codestr)
    f.close()

    cmd="g++ -o msdkcheck msdkcheck_tmp.c -I/opt/intel/mediasdk/include -L/opt/intel/mediasdk/lib/lin_x64 -lmfx -lva -ldl"
    sts=os.system(cmd)
    if (sts>0): 
        print_info("could not compile Media SDK test",loglevelcode.ERROR)

    out=run_cmd("./msdkcheck HW")
    print_info("Media SDK HW API level:"+out.strip(),loglevelcode.SUCCESS)


    out=run_cmd("./msdkcheck SW")
    print_info("Media SDK SW API level:"+out.strip(),loglevelcode.SUCCESS)

    os.remove("msdkcheck")
    os.remove("msdkcheck_tmp.c")


def check_OCL_caps():
    codestr="""
#include <CL/cl.h>
#include <stdio.h>
#define MAX_OCL_PLATFORMS 2
int main()
{
  cl_int err = CL_SUCCESS;
  cl_platform_id platforms[MAX_OCL_PLATFORMS];
  char platform_name[256];

  cl_uint num_of_platforms;
  err = clGetPlatformIDs(MAX_OCL_PLATFORMS, platforms, &num_of_platforms);

  for(cl_uint i = 0; i < num_of_platforms; ++i)
    {
      err = clGetPlatformInfo(platforms[i],CL_PLATFORM_NAME,256,platform_name,0);
      cl_uint gpucount,cpucount,accelcount;
      err = clGetDeviceIDs(platforms[i],CL_DEVICE_TYPE_GPU,0,0,&gpucount);
      err = clGetDeviceIDs(platforms[i],CL_DEVICE_TYPE_CPU,0,0,&cpucount);
      printf("platform:%s GPU %s CPU %s\\n",
          platform_name,
          (gpucount>0)?"OK":"FAIL",
          (cpucount>0)?"OK":"FAIL");
    }
}
"""

    if not os.path.exists("/opt/intel/opencl/include/CL/cl.h"):
        print_info("no OpenCL include files.  Are Intel components installed?",loglevelcode.ERROR)
        return

    f=open("oclcheck_tmp.c","w")
    f.write(codestr)
    f.close()

    cmd="g++ -o oclcheck oclcheck_tmp.c -I/opt/intel/opencl/include  -L/opt/intel/opencl -lOpenCL"
    sts=os.system(cmd)
    if (sts>0): 
        print_info("could not compile OpenCL test",loglevelcode.ERROR)

    out=run_cmd("./oclcheck")

    print_info("OpenCL check:"+out.strip(),loglevelcode.SUCCESS)

    os.remove("oclcheck")
    os.remove("oclcheck_tmp.c")



if __name__ == "__main__":


    if len(sys.argv)>1:
        if (sys.argv[1]=="--help"):
            print "usage: python sys_analyzer_linux.py [-v]"
            print "-v = verbose"

        if (sys.argv[1]=="-v"):
            GLOBAL_LOGLEVEL=2

    #HW media ready: processor,gpu ID (yes,no,advice)
    print "--------------------------"
    print "Hardware readiness checks:"
    print "--------------------------"
    sts=does_processor_have_gen_graphics()
    if (sts<loglevelcode.SUCCESS): sys.exit(1)

    #OS media ready: OS,glibc version,gcc version,nomodeset,gpuID (yes, no, advice, gold/generic)
    print "--------------------------"
    print "OS readiness checks:"
    print "--------------------------"    
    sts=is_OS_media_ready()
    if (sts<loglevelcode.SUCCESS): sys.exit(1)


    #MSS install correctness: vainfo, /dev/dri, check MSDK dirs, check OCL dirs, check MSDK/OCL funcs
    print "--------------------------"
    print "Media Server Studio Install:"
    print "--------------------------"      
    #in video group
    out=run_cmd("groups")
    if ("video" in out):
        print_info("user in video group",loglevelcode.SUCCESS)
    else:
        print_info("user not in video group.  Add with usermod -a -G video {user}",loglevelcode.ERROR)       

    if find_library("libva.so.1"):
        print_info("libva.so.1 found",loglevelcode.SUCCESS)
    else:
        print_info("libva.so.1 not found.  Check LD_LIBRARY_PATH contains '/usr/lib64;/usr/local/lib'",loglevelcode.ERROR)               

    #vainfo: exists,correct iHD used
    out=run_cmd("vainfo 2>&1")
    if ("iHD_drv_video.so" in out):
        print_info("Intel iHD used by libva",loglevelcode.INFO)
    else:
        print_info("libva not loading Intel iHD",loglevelcode.ERROR)
    
    if ("VAEntrypoint" in out):
        print_info("vainfo reports valid codec entry points",loglevelcode.SUCCESS)
    else:
        print_info("vainfo not reporting codec entry points",loglevelcode.ERROR)       

    #check i915 use
    out=run_cmd("lspci -v -s 0:02.0")
    if ("Kernel driver in use: i915" in out):
        print_info("i915 driver in use by Intel video adapter",loglevelcode.INFO)
    else:
        print_info("Intel video adapter not using i915",loglevelcode.ERROR)

    check_libdrm()


    print "--------------------------"
    print "Component Smoke Tests:"
    print "--------------------------"      
    check_msdk_api()

    check_OCL_caps()
