#!/bin/bash

#
#  hexorg.sh - hexdump with the right of setting the real origin address
#              (good for use with retrocomputing)
#
#  Copyright (c) 2020 Flavio Augusto (@facmachado)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#

#
# Declare some vars
#
HD=$(command -v hexdump)
LESS=$(command -v less)
THIS=$(basename "$0")

#
# Check some dependencies
#
if (($(tput cols) < 90 || $(tput lines) < 10)); then
  echo 'Error: Console below 90 columns x 10 lines' >&2
  exit 1
elif [ ! "$LESS" ]; then
  echo 'Error: less not installed' >&2
  exit 1
elif [ ! "$HD" ]; then
  echo 'Error: hexdump not installed' >&2
  exit 1
fi

#
# Help
#
function help() {
  echo "Usage: $THIS <-f|-i file> [-o hex_addr]"
  exit 0
}

#
# Check some args and if file exists
#
while (("$#")); do
  case $1 in
    -o) ORG=$((0x$(sed 's/[^0-9a-f]//g' <<<"$2"))) ;;
    -f|-i) FILE=$2 ;;
    *) help ;;
  esac
  shift 2
done
test ! "$FILE" && help
if [ ! -f "$FILE" ]; then
  echo 'Error: file not found' >&2
  exit 1
fi

#
# Start
#
echo "Hex dumping, please wait... (Use 'q' to exit next screen)"
T1="/tmp/$(basename "$FILE").tmp"
T0="/tmp/$THIS.tmp"

#
# Hexdump to pre-target
#
$HD -Cv "$FILE" >"$T0" 2>/dev/null

#
# Inject addresses before hexdump lines
#
while IFS= read -r i; do
  line=$((0x$(awk '{ print $1 }' <<<"$i")))
  line=$((line + ORG))
  printf '\e[1;97m%0.8x\e[0m  \e[2;37m%s\e[0m\n' "$line" "$i"
done <"$T0" >"$T1"

#
# Open target for analysis
#
clear && $LESS -KRP"--ADDR--  (Q) QUIT  00 01 02 03 04 05 06 07  \
08 09 0a 0b 0c 0d 0e 0f  |0123456789abcdef|" "$T1"

#
# Delete temps. End
#
rm -f "$T0" "$T1" &
