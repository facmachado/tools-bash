#!/bin/bash

#
#  randfunc.sh - random functions library
#
#  Copyright (c) 2020 Flavio Augusto (@facmachado)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#
#  Usage: source randfunc.sh
#

#
# Generates a number drawn, based on the quantity of tickets
# (up to 18 digits) and the waiting time in seconds. Tip: A
# negative value gives "more excitement" to the draw
# @param {number} quantity
# @param {number} time
# @returns {string}
#
function random_draw() {
  local c d e q s t
  q=$((${1:-1}))
  t=$((${2:-0}))
  d=$(($(printf %s ${q#-} | wc -c)))
  e=$(($(date -ud "${t#-} seconds" +%s)))

  while (($(date -u +%s) <= e)); do
    c=$(($(bc <<<"$(random_hash $d)")))
    s=$((c % q + 1))
    if ((s < 1 || d > 18)); then
      printf '\r\e[1;31mOut of range (1-18 digits)\e[0m\n' >&2
      return 1
    else
      ((t < 0)) && printf "\\r%0.${d}d" "$c"
    fi
  done

  printf "\\r%0.${d}d" "$s"
}

#
# Generates a GUID/UUID-like identifier. If available,
# uses uuidgen; otherwise, uses random_hash
# @returns {string}
#
function random_guid() {
  [ -x "$(command -v uuidgen)" ] &&  \
    uuidgen -r | tr -d \\n &&        \
    return 0

  local r
  r=$(random_hash 32 16)

  printf %s "${r:0:8}-${r:8:4}-${r:12:4}-${r:16:4}-${r:20:12}"
}

#
# Generates a random number (or hash) with base
# 2 (binary), 8 (octal), 10 (decimal) ou 16 (hexadecimal)
# @param {number} size
# @param {number} radix
# @returns {string}
#
function random_hash() { (
  usage() {
    echo 'Usage: random_hash <size> [2|8|10|16]'
  }

  local b l
  l=$(($1))
  b=$((${2:-10}))

  ((l < 1)) && usage && return 0
  case $b in
    2)   readonly r='01'                                        ;;
    8)   readonly r='0-7'                                       ;;
    10)  readonly r='0-9'                                       ;;
    16)  readonly r='0-9a-f'                                    ;;
    *)   echo -e "Radix not valid!\\n$(usage)" >&2 && return 1  ;;
  esac

  tr -dc $r </dev/urandom | head -c $l
) }

#
# Generates a random word, with some special characters
# @param {number} max
# @returns {string}
#
function random_word() {
  local l x
  x=$(($1))
  ((x < 1)) &&                          \
    echo 'Usage: random_word <max>' &&  \
    return 0
  l=$((RANDOM % x + 1))

  tr -dc '[:graph:]' </dev/urandom | head -c $l
}
