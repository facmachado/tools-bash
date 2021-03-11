#!/bin/bash

#
#  hexorg.sh - file hexdump with real origin address settable
#              (good for use with retrocomputing)
#
#  Copyright (c) 2021 Flavio Augusto (@facmachado)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#

#
# Checks some dependencies
#
if (($(tput cols) < 80 || $(tput lines) < 10)); then
  echo 'Error: Console screen below 80 columns x 10 lines' >&2
  exit 1
elif [ ! "$(command -v less)" ]; then
  echo 'Error: less not installed' >&2
  exit 1
elif [ ! "$(command -v xxd)" ]; then
  echo 'Error: xxd not installed' >&2
  exit 1
fi

#
# Shows help
#
function usage() {
  echo "Usage: $(basename "$0") <-f file> [-o hex_addr]"
}

#
# Checks args
#
while (("$#")); do
  case $1 in
    -f)  file=$2                                  ;;
    -o)  org=${2:-0} && org=0x${org//[^0-9a-f]/}  ;;
    *)   usage && exit 0                          ;;
  esac
  shift 2
done

#
# Checks if file exists
#
if [ ! "$file" ]; then
  usage && exit 0
elif [ ! -f "$file" ]; then
  echo 'Error: file not found' >&2
  exit 1
fi

#
# Opens file for analysis
#
xxd -g1 -o "$org" "$file" | less -KRP "(Q) QUIT  \
00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  \
0123456789abcdef"
