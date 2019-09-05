#!/bin/bash -eux

# This is template
# copy it to ~/.config/mobster/onTimeStart.sh and edit as you want

## parse options
set -- $(getopt d:n:b:m: "$@")
if [ $? != 0 ]; then
    echo "Usage: $0 [-d driver] [-n navigator] [-b isBreak] [-m minute]" 1>&2
    exit 1
fi
for OPT in "$@"; do
    case $OPT in
    -d)
        driver=$2
        shift 2
        ;;
    -n)
        navigator=$2
        shift 2
        ;;
    -b)
        is_break=$2
        shift 2
        ;;
    -m)
        minute=$2
        shift 2
        ;;
    --)
        shift
        break
        ;;
    esac
done

## do something
