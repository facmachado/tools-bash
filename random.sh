#!/bin/bash

#
#  random.sh - random functions library
#
#  Copyright (c) 2021 Flavio Augusto (@facmachado)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#
#  Usage: source random.sh
#

#
# Generates a number drawn, based on the quantity of tickets
# (up to 18 digits) and the waiting time in seconds. Tip: A
# negative value gives "more excitement" to the draw
# @param {number} qty
# @param {number} time
# @returns {string}
#
function random_draw() {
  local count digits end qty stop time
  qty=$((${1:-1}))   # Default qty is 1 ticket
  time=$((${2:-1}))  # Default time is 1 second
  end=$(($(date -ud "${time#-} seconds" +%s)))
  digits=$(($(printf %s ${qty#-} | wc -c)))

  if ((qty < 1 || digits > 18)); then
    printf '\r\e[1;31mOut of range (1-18 digits)\e[0m\n' >&2
    return 1
  fi
  while (($(date -u +%s) <= end)); do
    count=$(($(bc <<<"$(random_hash $digits)")))
    stop=$((count % qty + 1))
    ((time < 0)) && printf "\\r%0.${digits}d" "$count"
  done

  printf "\\r%0.${digits}d" "$stop"
}

#
# Generates a GUID/UUID-like identifier. If available,
# uses uuidgen; otherwise, uses random_hash
# @returns {string}
#
function random_guid() {
  if [ "$(command -v uuidgen)" ]; then
    uuidgen -r | tr -d \\n
    return 0
  fi

  local hash
  hash=$(random_hash 32 16)

  printf %s "${hash:0:8}-${hash:8:4}-${hash:12:4}-${hash:16:4}-${hash:20:12}"
}

#
# Generates a random number (or hash) with base
# 2 (binary), 8 (octal), 10 (decimal) ou 16 (hex)
# @param {number} size
# @param {number} base
# @returns {string}
#
function random_hash() { (
  local base range size
  base=$((${2:-10}))  # Default base is 10
  size=$(($1))

  function usage() {
    echo 'Usage: random_hash <size> [2|8|10|16]'
  }

  ((size < 1)) && usage && return 0
  case $base in
    2)   readonly range='01'                                   ;;
    8)   readonly range='0-7'                                  ;;
    10)  readonly range='0-9'                                  ;;
    16)  readonly range='0-9a-f'                               ;;
    *)   echo -e "Base not valid!\\n$(usage)" >&2 && return 1  ;;
  esac

  tr -dc $range </dev/urandom 2>/dev/null | head -c $size
) }

#
# Generates a MAC address
# @returns {string}
#
function random_mac() {
  local addr
  addr=$(random_hash 12 16)

  printf %s "${addr:0:2}:${addr:2:2}:${addr:4:2}:${addr:6:2}:${addr:8:2}:${addr:10:2}"
}

#
# Generates a random word, with some special characters
# @param {number} limit
# @returns {string}
#
function random_word() {
  local limit size
  limit=$(($1))
  if ((limit < 1)); then
    echo 'Usage: random_word <limit>'
    return 0
  fi
  size=$((RANDOM % limit + 1))

  tr -dc '[:graph:]' </dev/urandom 2>/dev/null | head -c $size
}
