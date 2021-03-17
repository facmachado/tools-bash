#!/bin/bash

#
#  hexorg.sh - file hex dump with user-defined origin address (offset)
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
if (($(tput cols) < 80 || $(tput lines) < 24)); then
  echo 'Error: screen below 80 columns x 24 lines' >&2
  exit 1
elif [ ! "$(command -v less)" ]; then
  echo 'Error: less not installed' >&2
  exit 1
elif [ ! "$(command -v xxd)" ]; then
  echo 'Error: xxd not installed' >&2
  exit 1
fi

#
# Checks if one or two arguments are defined
#
if ((${#*} < 1 || ${#*} > 2)); then
  echo "Usage: $(basename "$0") <file|-> [hex_addr]"
  exit 1
fi

#
# Checks if file (or stdin) exists
#
if [ ! -f "$1" -a "$1" != '-' ]; then
  echo 'Error: file not found' >&2
  exit 1
fi

#
# Formats offset as value for xxd argument
#
org=$(sed 's/^0x//;s/[^0-9a-f]//g' <<<"$2")
org=${org:-0}

#
# Opens file for analysis with less
#
less -KRP "--ADDR--  00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  \
0123456789abcdef" < <(xxd -g1 -o "0x$org" "$1" 2>/dev/null)
