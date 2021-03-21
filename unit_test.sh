#!/bin/bash

#
#  unit_test.sh
#
#  Copyright (c) 2021 Flavio Augusto (@facmachado)
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

#
# Marks task as successful
#
function check() {
  sleep 0.1
  printf '\r\033[1;32m✓\033[0m\n'
}

#
# Unit test common routines
#

function oneTimeSetUp() {
  src_dir=$(dirname "${BASH_SOURCE[0]}")
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
# Scenarios
#

function testSource() {
  printf '. source ascii.sh '
  source "$src_dir/ascii.sh"
  assertEquals 'ascii.sh' 0 $? && check

  printf '. source random.sh '
  source "$src_dir/random.sh"
  assertEquals 'random.sh' 0 $? && check

  printf '. source wol.sh '
  source "$src_dir/wol.sh"
  assertEquals 'wol.sh' 0 $? && check
}

function testAscii() {
  local result

  printf '. ascii_bin 123456 '
  result=$(ascii_bin 123456)
  assertEquals 'ascii_bin 123456' 001100010011001000110011001101000011010100110110 "$result" && check

  printf '. ascii_hex 123456 '
  result=$(ascii_hex 123456)
  assertEquals 'ascii_hex 123456' 313233343536 "$result" && check

  printf '. bin_ascii 001100010011001000110011001101000011010100110110 '
  result=$(bin_ascii 001100010011001000110011001101000011010100110110)
  assertEquals 'bin_ascii 001100010011001000110011001101000011010100110110' 123456 "$result" && check

  printf '. hex_ascii 313233343536 '
  result=$(hex_ascii 313233343536)
  assertEquals 'hex_ascii 313233343536' 123456 "$result" && check
}

function testRandom() {
  local result

  printf '. random_hash 8 2 '
  result=$(random_hash 8 2)
  assertNotContains 'random_hash 8 2' "$result" 2 && check
  printf '. random_hash 4 8 '
  result=$(random_hash 4 8)
  assertNotContains 'random_hash 4 8' "$result" 9 && check
  printf '. random_hash 5 10 '
  result=$(random_hash 5 10)
  assertNotContains 'random_hash 5 10' "$result" a && check
  printf '. random_hash 2 16 '
  result=$(random_hash 2 16)
  assertNotContains 'random_hash 2 16' "$result" g && check

  printf '. random_word 12 '
  result=$(random_word 12 | wc -c)
  assertTrue 'random_word 12' "(($result <= 12))" && check

  printf '. random_draw 1000 1 '
  random_draw 1000 1 >/dev/null
  assertEquals 'random_draw 1000 1' 0 $? && check
  printf '. random_draw 1000 -1 '
  random_draw 1000 -1 >/dev/null
  assertEquals 'random_draw 1000 -1' 0 $? && check

  printf '. random_guid '
  result=$(random_guid)
  assertContains 'random_guid' "$result" '-' && check

  printf '. random_mac '
  result=$(random_mac)
  assertContains 'random_mac' "$result" ':' && check
}

function testWol() {
  local mac result
  mac=$(random_mac)

  printf ". wol_str $mac "
  result=$(wol_str "$mac" | wc -c)
  assertEquals "wol_str $mac" 102 "$result" && check

  printf ". wol_send $mac "
  wol_send "$mac"
  assertEquals "wol_send $mac" 0 $? && check
}

function testHexorg() {
  local result

  printf '. call hexorg '
  result=$(bash $src_dir/hexorg.sh)
  assertContains 'call hexorg' "$result" 'Usage:' && check
}

#
# Calls shunit2
#
# shellcheck disable=SC1091
source shunit2
