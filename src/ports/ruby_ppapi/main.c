/* Copyright (c) 2013 The Native Client Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file. */

#undef RUBY_EXPORT
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <libtar.h>
#include <locale.h>
#include <ruby.h>
#include <stdio.h>
#include <sys/mount.h>

#include "nacl_io/nacl_io.h"
#include "ppapi_simple/ps_main.h"

#ifdef __x86_64__
#define NACL_ARCH "x86_64"
#elif defined __i686__
#define NACL_ARCH "x86_32"
#elif defined __arm__
#define NACL_ARCH "arm"
#elif defined __pnacl__
#define NACL_ARCH "pnacl"
#else
#error "unknown arch"
#endif

#define DATA_ARCHIVE "rbdata-" NACL_ARCH ".tar"

static int setup_unix_environment(const char* tarfile) {
  int ret = umount("/");
  if (ret) {
    printf("unmounting root fs failed\n");
    return 1;
  }
  ret = mount("", "/", "memfs", 0, NULL);
  if (ret) {
    printf("mounting root fs failed\n");
    return 1;
  }

  mkdir("/home", 0777);
  mkdir("/tmp", 0777);
  mkdir("/bin", 0777);
  mkdir("/etc", 0777);
  mkdir("/mnt", 0777);
  mkdir("/mnt/http", 0777);
  mkdir("/mnt/html5", 0777);

  const char* data_url = getenv("NACL_DATA_URL");
  if (!data_url)
    data_url = "./";

  ret = mount(data_url, "/mnt/http", "httpfs", 0,
        "allow_cross_origin_requests=true,allow_credentials=false");
  if (ret) {
    printf("mounting http filesystem failed\n");
    return 1;
  }

  // Ignore failures from mounting html5fs.  For example, it will always
  // fail in incognito mode.
  mount("/", "/mnt/html5", "html5fs", 0, "");

  // Extra tar achive from http filesystem.
  if (tarfile) {
    TAR* tar;
    char filename[PATH_MAX];
    strcpy(filename, "/mnt/http/");
    strcat(filename, tarfile);
    ret = tar_open(&tar, filename, NULL, O_RDONLY, 0, 0);
    if (ret) {
      printf("error opening luadata.tar\n");
      return 1;
    }

    ret = tar_extract_all(tar, "/");
    if (ret) {
      printf("error extracting luadata.tar\n");
      return 1;
    }

    ret = tar_close(tar);
    assert(ret == 0);
  }

  // Setup environment
  setenv("HOME", "/home", 1);
  setenv("PATH", "/bin", 1);
  setenv("USER", "user", 1);
  setenv("LOGNAME", "user", 1);

  // Setup environment variables
  setlocale(LC_CTYPE, "");
  return 0;
}

int ruby_main(int argc, char **argv) {
  printf("Extracting: %s ...\n", DATA_ARCHIVE);
  if (setup_unix_environment(DATA_ARCHIVE))
    return 1;

  printf("Launching irb ...\n");
  ruby_sysinit(&argc, &argv);
  {
    RUBY_INIT_STACK;
    ruby_init();
    return ruby_run_node(ruby_options(argc, argv));
  }
}

PPAPI_SIMPLE_REGISTER_MAIN(ruby_main)
