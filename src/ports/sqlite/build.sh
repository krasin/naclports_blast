#!/bin/bash
# Copyright (c) 2013 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

source pkg_info
source ../../build_tools/common.sh

MAKE_TARGETS="CCLD=\$(CXX) all"
export LIBS="-lnacl_io -pthread"
if [ ${NACL_GLIBC} != "1" ]; then
  EXTRA_CONFIGURE_ARGS=--disable-dynamic-extensions
  EXECUTABLE_DIR=.
else
  EXECUTABLE_DIR=.libs
fi

PackageInstall() {
  local SRC_DIR=${NACL_PACKAGES_REPOSITORY}/${PACKAGE_DIR}
  if [ -f ${SRC_DIR}/shell.c ]; then
    touch ${SRC_DIR}/shell.c
  fi

  DefaultPackageInstall
  if [ ${NACL_ARCH} != "pnacl" ]; then
    WriteSelLdrScript sqlite3 ${EXECUTABLE_DIR}/sqlite3${NACL_EXEEXT}
  else
    local pexe=${EXECUTABLE_DIR}/sqlite3${NACL_EXEEXT}
    TranslateAndWriteSelLdrScript ${pexe} x86-64 sqlite3.x86-64.nexe sqlite3
  fi

  # Build (at least shell.c) again but this time with nacl_io and -DPPAPI
  Banner "Build sqlite3_ppapi"
  touch ${SRC_DIR}/shell.c
  sed -i.bak "s/sqlite3\$(EXEEXT)/sqlite3_ppapi\$(EXEEXT)/" Makefile
  sed -i.bak "s/CFLAGS = /CFLAGS = -DPPAPI /" Makefile
  sed -i.bak "s/-lnacl_io/-lppapi_simple -lnacl_io -pthread -lppapi_cpp -lppapi/" Makefile
  BuildStep

  PUBLISH_DIR="${NACL_PACKAGES_PUBLISH}/sqlite"
  if [ "${NACL_ARCH}" = "pnacl" ]; then
    PUBLISH_DIR+=/pnacl
  else
    PUBLISH_DIR+=/${NACL_LIBC}
  fi

  MakeDir ${PUBLISH_DIR}

  local exe=${PUBLISH_DIR}/sqlite3_ppapi_${NACL_ARCH}${NACL_EXEEXT}

  LogExecute mv ${EXECUTABLE_DIR}/sqlite3_ppapi${NACL_EXEEXT} ${exe}
  if [ "${NACL_ARCH}" = "pnacl" ]; then
    LogExecute ${PNACLFINALIZE} ${exe}
  fi

  pushd ${PUBLISH_DIR}
  LogExecute python ${NACL_SDK_ROOT}/tools/create_nmf.py \
      sqlite3_ppapi*${NACL_EXEEXT} \
      -s . \
      -o sqlite.nmf
  LogExecute python ${TOOLS_DIR}/create_term.py sqlite.nmf
  popd

  InstallNaClTerm ${PUBLISH_DIR}
}

PackageInstall
exit 0
