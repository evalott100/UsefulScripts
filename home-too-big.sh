#! /bin/bash
t=$(quota|awk 'FNR == 4 {print $2}')
du . --exclude=.snapshot --max-depth=1 |\
    sed '$d'|\
    sort -rn -k1 |\
    awk -v t=$t 'OFMT="%d" {M=64; for(a=0;a<$1;a++){if (a>c){c=a}}br=a/c;b=M*br;for(x=0;x<b;x++) {printf "\033[1;31m""|" "\033[0m"}print " "$2" "(a/t*100)"% total"}'

