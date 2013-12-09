#!/bin/bash
# Copyright (c) 2011 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

source pkg_info
source ../../build_tools/common.sh

EXECUTABLES="src/lua${NACL_EXEEXT} src/luac${NACL_EXEEXT}"

BuildStep() {
  Banner "Build ${PACKAGE_NAME}"
  ChangeDir ${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}
  if [ "${NACL_GLIBC}" = "1" ]; then
    PLAT=nacl-glibc
  else
    PLAT=nacl-newlib
  fi
  if [ "${LUA_NO_READLINE:-}" = "1" ]; then
    PLAT+=-basic
  fi
  LogExecute make PLAT=${PLAT} clean
  set -x
  make AR="${NACLAR} rcu" RANLIB="${NACLRANLIB}" CC="${NACLCC}" PLAT=${PLAT} EXEEXT=${NACL_EXEEXT} -j${OS_JOBS}
  set +x
}


TestStep() {
  Banner "Testing ${PACKAGE_NAME}"
  pushd src
  if [ "${NACL_ARCH}" = pnacl ]; then
    # Just do the x86-64 version for now.
    TranslateAndWriteSelLdrScript lua.pexe x86-64 lua.x86-64.nexe lua
    TranslateAndWriteSelLdrScript luac.pexe x86-64 luac.x86-64.nexe luac
  else
    WriteSelLdrScript lua lua.nexe
    WriteSelLdrScript luac luac.nexe
  fi
  popd

  if [ "${NACL_ARCH}" != "arm" ]; then
    LogExecute make PLAT=${PLAT} test
  fi
}


InstallStep() {
  Banner "Install ${PACKAGE_NAME}"

  # TODO: side-by-side install
  LogExecute make PLAT=${PLAT} EXEEXT=${NACL_EXEEXT} "INSTALL_TOP=${NACLPORTS_PREFIX}" install
}


PackageInstall
exit 0
