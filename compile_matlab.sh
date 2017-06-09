#!/bin/bash
# vim ft=sh

mkdir -p compiled
MEX=$MATLABROOT/bin/mex
find . -name '*.c' | xargs -L 1 $MEX -v CC=gcc LD=gcc COPTIMFLAGS='-O2 -DNDEBUG' -outdir compiled
