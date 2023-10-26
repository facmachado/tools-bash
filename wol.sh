#!/bin/bash

#
#  wol.sh - wake-on-lan functions library
#
#  Copyright (c) 2023 Flavio Augusto (@facmachado, PP2SH)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#
#  Usage: source ascii.sh
#         source wol.sh
#

#
# Checks for netcat
#
if [ ! "$(command -v nc)" ]; then
  echo 'Error: netcat not installed' >&2
  return 1
fi

#
# Sends the Magic Packet
# @param {string} mac
#
function wol_send() {
  local bc mac port
  bc=255.255.255.255
  mac=$1
  port=9

  nc -w1 -u -b $bc $port < <(wol_str "$mac")
}

#
# Converts from MAC address to Magic Packet string
# @param {string} mac
# @returns {string}
#
function wol_str() {
  local mac magic
  mac=$(printf %s "${1,,}" | tr -d ' :-')
  magic=$(printf f%.0s {1..12}; printf "${mac}%.0s" {1..16})

  hex_ascii "$magic"
}
