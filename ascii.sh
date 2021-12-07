#!/bin/bash

#
#  ascii.sh - ASCII strings functions library
#
#  Copyright (c) 2021 Flavio Augusto (@facmachado)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#
#  Usage: source ascii.sh
#

#
# Checks for xxd
#
if [ ! "$(command -v xxd)" ]; then
  echo 'Error: xxd not installed' >&2
  return 1
fi

#
# Converts from ASCII string to binary string
# (0s or 1s only, no prefix/sulfix b)
# @param {string} input or <file
# @returns {string}
#
function ascii_bin() {
  if ((${#1} > 0)); then
    printf %s "$1" | xxd -b -g0 | cut -d' ' -f2 | tr -d ' \n'
  else
    xxd -b -g0 | cut -d' ' -f2 | tr -d ' \n'
  fi
}

#
# Converts from ASCII string to hex string
# (lowercase, no prefix/sulfix x or h)
# @param {string} input or <file
# @returns {string}
#
function ascii_hex() {
  if ((${#1} > 0)); then
    printf %s "$1" | xxd -p | tr -d \\n
  else
    xxd -p | tr -d \\n
  fi
}

#
# Converts from binary string to ASCII string
# @param {string} input
# @returns {string}
#
function bin_ascii() {
  local data pad size
  size=$(printf %s "$1" | wc -c)
  ((size % 8 < 1)) && pad=0 || pad=$((8 - size % 8))
  ((pad > 0)) && data="$(printf %0${pad}g 0)$1" || data=$1

  hex_ascii "$(bc <<<"obase=16; ibase=2; $data")"
}

#
# Converts from hex string to ASCII string
# @param {string} input
# @returns {string}
#
function hex_ascii() {
  local data pad size
  size=$(printf %s "$1" | wc -c)
  ((size % 2 < 1)) && pad=0 || pad=$((2 - size % 2))
  ((pad > 0)) && data="$(printf %0${pad}g 0)$1" || data=$1

  xxd -r -p <<<"$data"
}
