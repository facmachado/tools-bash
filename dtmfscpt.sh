#!/bin/bash

#
# Check for SoX
#
if [ ! "$(command -v sox)" ]; then
  echo 'Error: SoX not installed' >&2
  return 1
fi

#
# Array for DTMF tones: [0 1 2 3 4 5 6 7 8 9 A B C D * #]
#
declare -a DTMF_FREQSX DTMF_FREQSY

# Horizontal tones
DTMF_FREQSX=(941 697 697 697 770 770 770 852 852 852 697 770 852 941 941 941)

# Vertical tones
DTMF_FREQSY=(1336 1209 1336 1477 1209 1336 1477 1209 1336 1477 1633 1633 1633 1633 1209 1477)

#
# Command line dialer
# shellcheck disable=SC2086
#
function dial() {
  if [ ! "$1" ]; then
    echo "usage: dial <digits>" >&2
    return
  fi
  local cmd len max seq
  seq=$(sed 's/[EF]//g;s/\*/E/g;s/\#/F/g;s/[^0-9A-F]//g' <<<"${1^^}")
  len=${#seq}
  max=70
  if ((len > max)); then
    echo "error: sequence is limited to $max digits" >&2
    return
  fi
  for ((i=0; i<len; i++)); do
    cmd+="synth .2 sine ${DTMF_FREQSX[0x${seq:$i:1}]} sine ${DTMF_FREQSY[0x${seq:$i:1}]} : synth .1 sine 0 : "
  done
  play -q -n -c 1 -b 16 -r 8k ${cmd::-3} 2>&-
}

#
# Internal shortcut for 'sleep'
#
function wait() {
  test "$1" && sleep "$1" || echo "usage: wait <secs>" >&2
}

#
# List commands
# shellcheck disable=SC2207
#
CMDS=(':' 'echo' 'exit' $(declare -F | cut -d' ' -f3))

#
# Prompt if file not given. If given, try to find it
#
if [ "$1" ] && [ ! -e "$(realpath "$1")" ]; then
  echo "error: $1 not found" >&2
  exit 1
fi
INPUT=$(realpath "${1:-/dev/stdin}")

#
# Our interpreter's main loop
#
while read -r -e -p '% ' -a line; do
  if ! grep -q -w "${line[0]}" <<<"${CMDS[@]}"; then
    echo "error: invalid command '${line[0]}'" >&2
    continue
  fi
  "${line[@]}"
done <"$INPUT"
