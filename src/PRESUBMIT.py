# Copyright (c) 2011 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Documentation on PRESUBMIT.py can be found at:
# http://www.chromium.org/developers/how-tos/depottools/presubmit-scripts

import subprocess


_EXCLUDED_PATHS = (
    # patch_configure.py contains long lines embedded in multi-line
    # strings.
    r"^build_tools[\\\/]patch_configure.py",
)

def CheckBuildbot(input_api, output_api):
  try:
    subprocess.check_call('build_tools/bots/test.sh')
  except subprocess.CalledProcessError as e:
    return [output_api.PresubmitError('build_tools/bots/test.sh failed')]
  return []

def CheckMirror(input_api, output_api):
  try:
    subprocess.check_call(['build_tools/update_mirror.py', '--check'])
  except subprocess.CalledProcessError as e:
    message = 'update_mirror.py --check failed.'
    message += '\nRun build_tools/update_mirror.py to update.'
    return [output_api.PresubmitError(message)]
  return []

def CheckChangeOnUpload(input_api, output_api):
  report = []
  affected_files = input_api.AffectedFiles(include_deletes=False)
  report.extend(CheckBuildbot(input_api, output_api))
  report.extend(input_api.canned_checks.PanProjectChecks(
      input_api, output_api, project_name='Native Client',
      excluded_paths=_EXCLUDED_PATHS))
  return report


def CheckChangeOnCommit(input_api, output_api):
  report = []
  report.extend(CheckChangeOnUpload(input_api, output_api))
  report.extend(CheckMirror(input_api, output_api))
  report.extend(input_api.canned_checks.CheckTreeIsOpen(
      input_api, output_api,
      json_url='http://naclports-status.appspot.com/current?format=json'))
  return report
