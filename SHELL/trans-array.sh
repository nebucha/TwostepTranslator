#!/bin/bash

tmp=tmp_$$
shelld=$(cd $(dirname $0) && pwd)
TOOLS=$shelld/../TOOLS

programname=$(basename $0)
version=1.0

usage() {
    echo "Usage: $programname [-from FROM] -to TO FILE"
    echo "  This script is ~."
    echo
    echo "Options:"
    echo "  -h, --help"
    echo "  -v, --version"
    echo "  -from LANGUAGE"
    echo "  -to LANGUAGE"
    echo "  -text TEXT"
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
fi                          |
sed -e 's/ /_/g'            > $tmp-inputtext

if [ ! -s $tmp-inputtext ]; then
    echo "$programname: too few arguments" 1>&2
    exit 1
fi

[ -z $from ] && from=@

key1=$(head -1 $shelld/.key/key)
url="https://api.microsofttranslator.com/V2/Http.svc/TranslateArray"

echo $from $to   > $tmp-from-to
mojihame -l____TEXT____ request-template.xml $tmp-inputtext     |
mojihame - $tmp-from-to                       > $tmp-request.xml

curl -s -X POST --header 'Content-Type:application/xml' \
            --header 'Accept:application/xml' \
            --header 'Ocp-Apim-Subscription-Key:'${key1} \
            --header "Transfer-Encoding: chunked" \
            -d @$tmp-request.xml      \
            ${url}                              > $tmp-response.xml

# XMLをパース
##cat $tmp-response.xml               |
##grep -o -E '<TranslatedText>[^<]*'  |
##sed -e 's/<TranslatedText>//g'      > $tmp-result
cat $tmp-response.xml                   |
$TOOLS/parse_response                   

rm -f $tmp-*
exit 0