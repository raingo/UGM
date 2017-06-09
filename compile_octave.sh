#!/bin/bash
# vim ft=sh

mkdir -p compiled
find . -name '*.c' | xargs -L 1 python -c "import os.path as osp; import sys; print 'compiled/' + osp.splitext(osp.basename(sys.argv[1]))[0], sys.argv[1];" | xargs -L 1 mkoctfile --mex -v -s --output
