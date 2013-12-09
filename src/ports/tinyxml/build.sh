#!/bin/bash
# Copyright (c) 2011 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


source pkg_info
source ../../build_tools/common.sh


BuildStep() {
  Banner "Building ${PACKAGE_NAME}"
  ChangeDir ${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}
  export CC=${NACLCC}
  export CXX=${NACLCXX}
  export AR=${NACLAR}
  export LD=${NACLLD}
  export RANLIB=${NACLRANLIB}
  make clean
  make OUTPUT=libtinyxml.a
}


InstallStep() {
  # copy libs and headers manually
  Banner "Installing ${PACKAGE_NAME} to ${NACLPORTS_PREFIX}"
  ChangeDir ${NACLPORTS_INCLUDE}
  Remove ${PACKAGE_NAME}
  MakeDir ${PACKAGE_NAME}
  readonly THIS_PACKAGE_PATH=${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}
  cp ${THIS_PACKAGE_PATH}/*.h ${PACKAGE_NAME}/
  ChangeDir ${NACLPORTS_LIBDIR}
  cp ${THIS_PACKAGE_PATH}/*.a .
}


PackageInstall
exit 0
