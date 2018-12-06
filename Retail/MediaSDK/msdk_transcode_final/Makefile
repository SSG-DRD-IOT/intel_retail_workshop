EXEC=../build/msdk_transcode
INCS= \
  ../common/common_utils.h \
  ../common/common_vaapi.h \
  ../common/linux_defs.h
SRCS= \
  src/msdk_transcode.cpp \
  ../common/common_utils.cpp \
  ../common/common_utils_linux.cpp \
  ../common/common_vaapi.cpp

CFLAGS=-std=c++11 -I/usr/local/include -I../common -I$(MFX_HOME)/include/mfx
LFLAGS=-L$(MFX_HOME)/lib -lmfx -lva -lva-drm -lpthread -lrt -ldl

$(EXEC): $(INCS) $(SRCS) Makefile
	mkdir -p ../build
	g++ -o $(EXEC) $(SRCS) $(CFLAGS) $(LFLAGS)

.PHONY: clean
clean:
	rm $(EXEC)
