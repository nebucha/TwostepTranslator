#!/bin/bash

tmp=tmp_$$
shelld=$(cd $(dirname $0) && pwd)
TOOLS=$shelld/../TOOLS

programname=$(basename $0)
version=1.0

usage() {
    echo "Usage: $programname [-from FROM] -to TO -text TEXT FILE"
    echo "  This script is ~."
    echo
    echo "Options:"
    echo "  -h, --help"
    echo "  -v, --version"
    echo "  -from ARG"
    echo "  -to ARG"
    echo "  -text ARG"
    echo
    exit 1
}

# get options
for OPT in "$@"
do
    case "$OPT" in
        '-h'|'--help' )
            usage
            exit 1
            ;;
        '-v'|'--version' )
            echo $version
            exit 1
            ;;
        '-from' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$programname: option requires an argument -- $1" 1>&2
                exit 1
            fi
            from="$2"
            shift 2
            ;;
        '-to' )
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "$programname: option requires an argument -- $1" 1>&2
                exit 1
            fi
            to="$2"
            shift 2
            ;;
        '--'|'-' )
            shift 1
            param+=( "$@" )
            break
            ;;
        -*)
            echo "$programname: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
            exit 1
            ;;
        *)
            if [[ ! -z "$1" ]] && [[ ! "$1" =~ ^-+ ]]; then
                #param=( ${param[@]} "$1" )
                param+=( "$1" )
                shift 1
            fi
            ;;
    esac
done

if [ -z $to ]; then
    echo "$programname: option -to is necessary" 1>&2
    exit 1
fi

if [ -z $param ]; then
    cat -
else
    for file in "$param"; do
       case "$file" in
         -)  :             ;;
         /*) :             ;;
         *)  file="./$file";;
       esac
       cat "$file"
     done
fi                        > $tmp-inputtext

if [ ! -s $tmp-inputtext ]; then
    echo "$programname: too few arguments" 1>&2
    exit 1
fi

cat $tmp-inputtext

key1=$(head -1 $shelld/.key/key)
key2=$(tail -1 $shelld/.key/key)
url="https://api.microsofttranslator.com/V2/Http.svc/Translate"

middle="en"

cat $tmp-inputtext  |
while read text; do

    echo $text
    text1=$(echo $text | $TOOLS/urlencoder.sh)

    curl -s -X GET --header 'Content-Type:application/json' \
            --header 'Accept:application/xml' \
            --header 'Ocp-Apim-Subscription-Key:'${key1} \
            ${url}?to=${middle}\&text=${text1}    |
    sed -e 's/<string [^>]*>//1' -e 's/<\/string>//1'           > $tmp-result1

    cat $tmp-result1

    text2=$(head -1 $tmp-result1 | $TOOLS/urlencoder.sh)
    curl -s -X GET --header 'Content-Type:application/json' \
            --header 'Accept:application/xml' \
            --header 'Ocp-Apim-Subscription-Key:'${key1} \
            ${url}?from=${middle}\&to=${to}\&text=${text2}    |
    sed -e 's/<string [^>]*>//1' -e 's/<\/string>//1'           > $tmp-result2

    cat $tmp-result2

done

rm -f $tmp-*
exit 0