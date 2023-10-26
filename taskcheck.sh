#!/bin/bash

#
#  taskcheck.sh - adendum for use in shunit2 scripts
#
#  Copyright (c) 2023 Flavio Augusto (@facmachado, PP2SH)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#

#
# Defines task name
#
function task() {
  echo -n ". $1 "
}

#
# Marks task as successful
#
function check() {
  sleep 0.1
  echo -e '\r\033[1;32m✓\033[0m'
}
