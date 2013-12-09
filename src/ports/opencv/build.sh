#!/bin/bash
# Copyright 2013 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

source pkg_info
source ../../build_tools/common.sh

ConfigureStep() {
  EXTRA_CMAKE_ARGS="-DBUILD_SHARED_LIBS=OFF \
           -DWITH_FFMPEG=OFF \
           -DWITH_OPENEXR=OFF \
           -DWITH_CUDA=OFF \
           -DWITH_JASPER=OFF \
           -DWITH_OPENCL=OFF \
           -DBUILD_opencv_apps=OFF \
           -DBUILD_opencv_java=OFF \
           -DBUILD_SHARED_LIBS=OFF \
           -DBUILD_TESTS=OFF \
           -DBUILD_PERF_TESTS=OFF \
           -DBUILD_FAT_JAVA_LIB=OFF"
  CMakeConfigureStep
}

BuildStep() {
  # opencv build can fail when build with -jN.
  make
}

PackageInstall
exit 0
