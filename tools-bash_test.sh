#!/bin/bash

#
#  tools-bash_test.sh - testing environment for tools-bash
#
#  Copyright (c) 2023 Flavio Augusto (@facmachado, PP2SH)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#

#
# Checks for shunit2
#
if [ ! "$(command -v shunit2)" ]; then
  echo 'Error: shunit2 not installed' >&2
  exit 1
fi
src_dir=$(dirname "${BASH_SOURCE[0]}")
source "$src_dir/taskcheck.sh"

#
# Unit test common routines, like Selenium Webdriver
#

function oneTimeSetUp() {
  echo "Test start: $(date)"
}

function setUp() {
  echo
}

function tearDown() {
  sleep 0.2
}

function oneTimeTearDown() {
  echo -e "\nTest finish: $(date)"
}

#
# Test scenarios
#

function testSource() {
  task 'source ascii.sh'
  source "$src_dir/ascii.sh"
  assertEquals 'source ascii.sh' 0 $? && \
  check

  task 'source random.sh'
  source "$src_dir/random.sh"
  assertEquals 'source random.sh' 0 $? && \
  check

  task 'source wol.sh'
  source "$src_dir/wol.sh"
  assertEquals 'source wol.sh' 0 $? && \
  check

  task 'source brazil.sh'
  source "$src_dir/brazil.sh"
  assertEquals 'source brazil.sh' 0 $? && \
  check
}

function testAscii() {
  local result

  task 'ascii_bin'
  result=$(ascii_bin 123456)
  assertEquals 'ascii_bin' 001100010011001000110011001101000011010100110110 "$result" && \
  check

  task 'ascii_hex'
  result=$(ascii_hex 123456)
  assertEquals 'ascii_hex' 313233343536 "$result" && \
  check

  task 'bin_ascii'
  result=$(bin_ascii 001100010011001000110011001101000011010100110110)
  assertEquals 'bin_ascii' 123456 "$result" && \
  check

  task 'hex_ascii'
  result=$(hex_ascii 313233343536)
  assertEquals 'hex_ascii' 123456 "$result" && \
  check
}

function testRandom() {
  task 'random_hash with base 2'
  random_hash 8 2 >/dev/null
  assertEquals 'random_hash with base 2' 0 $? && \
  check

  task 'random_hash with base 8'
  random_hash 4 8 >/dev/null
  assertEquals 'random_hash with base 8' 0 $? && \
  check

  task 'random_hash with base 10'
  random_hash 5 10 >/dev/null
  assertEquals 'random_hash with base 10' 0 $? && \
  check

  task 'random_hash with base 16'
  random_hash 2 16 >/dev/null
  assertEquals 'random_hash with base 16' 0 $? && \
  check

  task 'random_word'
  random_word 12 >/dev/null
  assertEquals 'random_word' 0 $? && \
  check

  task 'random_draw'
  random_draw 1000 1 >/dev/null
  assertEquals 'random_draw' 0 $? && \
  check

  task 'random_draw with excitement'
  random_draw 1000 -1 >/dev/null
  assertEquals 'random_draw with excitement' 0 $? && \
  check

  task 'random_guid'
  random_guid >/dev/null
  assertEquals 'random_guid' 0 $? && \
  check

  task 'random_mac'
  random_mac >/dev/null
  assertEquals 'random_mac' 0 $? && \
  check
}

function testWol() {
  local mac result
  mac=$(random_mac)

  task 'wol_str'
  result=$(wol_str "$mac" | wc -c)
  assertEquals 'wol_str' 102 "$result" && \
  check

  task 'wol_send'
  wol_send "$mac"
  assertEquals 'wol_send' 0 $? && \
  check
}

function testBrazil() {
  task 'modulo_10'
  check

  task 'modulo_11'
  check

  task 'venc_utime'
  check

  task 'banco_nome'
  check

  task 'cpf_dv'
  check

  task 'cpf_gerar'
  check

  task 'cpf_validar'
  check

  task 'cnpj_dv'
  check

  task 'cnpj_gerar'
  check

  task 'cnpj_validar'
  check

  task 'boleto_barra'
  check

  task 'boleto_linha'
  check

  task 'boleto_info'
  check

  task 'convenio_barra'
  check

  task 'convenio_linha'
  check
}

function testHexorg() {
  task 'hexorg w/o parameters'
  bash "$src_dir/hexorg.sh" >/dev/null
  assertEquals 'hexorg w/o parameters' 1 $? && \
  check
}

#
# Calls shunit2
#
# shellcheck disable=SC1091
source shunit2
