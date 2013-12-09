#!/bin/bash
# Copyright (c) 2012 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

source pkg_info
source ../../build_tools/common.sh

EXAMPLE_DIR=${NACL_SRC}/ports/xaos
EXECUTABLES=bin/xaos

PatchStep() {
  DefaultPatchStep
  local src_dir="${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}"
  echo "copy nacl driver"
  cp -r "${START_DIR}/nacl-ui-driver" "${src_dir}/src/ui/ui-drv/nacl"
}

ConfigureStep() {
  Banner "Configuring ${PACKAGE_NAME}"

  # export the nacl tools
  export CC=${NACLCC}
  export CXX=${NACLCXX}
  # NOTE: non-standard flag NACL_LDFLAGS because of some more hacking below
  export CFLAGS="${NACLPORTS_CFLAGS} -D__NO_MATH_INLINES=1"
  export LDFLAGS="${NACLPORTS_LDFLAGS} -Wl,--undefined=PPP_GetInterface \
                  -Wl,--undefined=PPP_ShutdownModule \
                  -Wl,--undefined=PPP_InitializeModule \
                  -Wl,--undefined=original_main"
  export AR=${NACLAR}
  export RANLIB=${NACLRANLIB}
  export PKG_CONFIG_PATH=${NACLPORTS_LIBDIR}/pkgconfig
  export PKG_CONFIG_LIBDIR=${NACLPORTS_LIBDIR}

  export LIBS="-L${NACLPORTS_LIBDIR} -lppapi \
    -lpthread -l${NACL_CPP_LIB} -lm"

  CONFIG_FLAGS="--with-png=no \
      --with-long-double=no \
      --host=nacl \
      --with-x11-driver=no \
      --with-sffe=no"

  ChangeDir ${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}

  # xaos does not work with a build dir which is separate from the
  # src dir - so we copy src -> build
  Remove ${NACL_BUILD_SUBDIR}
  local tmp=${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}.tmp
  Remove ${tmp}
  cp -r ${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME} ${tmp}
  mv ${tmp} ${NACL_BUILD_SUBDIR}

  cd ${NACL_BUILD_SUBDIR}
  echo "Directory: $(pwd)"
  echo "run autoconf"
  rm ./configure
  autoconf
  echo "Configure options: ${CONFIG_FLAGS}"
  ./configure ${CONFIG_FLAGS}
}

InstallStep(){
  local out_dir=${NACL_PACKAGES_REPOSITORY}/${PACKAGE_NAME}
  local build_dir=${out_dir}/${NACL_BUILD_SUBDIR}
  local publish_dir="${NACL_PACKAGES_PUBLISH}/${PACKAGE_NAME}"

  MakeDir ${publish_dir}
  install ${START_DIR}/xaos.html ${publish_dir}
  install ${START_DIR}/xaos.nmf ${publish_dir}
  # Not used yet
  install ${build_dir}/help/xaos.hlp ${publish_dir}
  install ${build_dir}/bin/xaos ${publish_dir}/xaos_${NACL_ARCH}${NACL_EXEEXT}
}

PackageInstall
exit 0
