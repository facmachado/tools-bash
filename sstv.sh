#!/bin/bash

#
# Checks for SoX
#
if [ ! "$(command -v sox)" ]; then
  echo 'Error: SoX not installed' >&2
  return 1
fi


# VIS
cmd="\
synth .3  sine 1900 : synth .01 sine 1200 : \
synth .3  sine 1900 : synth .03 sine 1200 : \
synth .03 sine 1100 : synth .03 sine 1300 : \
synth .03 sine 1300 : synth .03 sine 1100 : \
synth .03 sine 1300 : synth .03 sine 1300 : \
synth .03 sine 1300 : synth .03 sine 1100 : \
synth .03 sine 1200 : synth .03 sine 1200 : "

for ((j=0; j<256; j++)); do
  cmd+="synth .138 sine 1900 : synth .012 sine 1200 : "
done

play -q -n -c 1 ${cmd::-3}
