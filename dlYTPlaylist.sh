#!/bin/bash

function invalidArgs(){
    if [[ "$quiet" -eq 0 ]]; then
        echo "Invalid number of arguments."
    fi
    helpAndExit
    exit 1;
}

function helpAndExit(){
    if [[ "$quiet" -eq 0 ]]; then
        echo "dlYTPlaylist [OPTIONS]"
        echo "    -h       Display this message and exit."
        echo "    -m       Create a metadata file which stores the original URL."
        echo "    -u [URL] The URL to use."
        echo "    -d [DIR] The directory to save to."
        echo "    -q       Suppresses all output."
        echo "    -n       Does not generate an m3u playlist file."
    fi
}

function convert(){
    if [[ `ls "$dlpath"/*."$1" -1 2>/dev/null | wc -l` != 0 ]]; then
        if [[ "$quiet" -eq 0 ]]; then
            echo "Converting all $1 files to mp3 format..."
        fi

        for i in "$dlpath"/*."$1"; do
            newName=`echo "$i" | sed -e "s/$1/mp3/"` || { exit 1; };
            ffmpeg `if [[ "$quiet" -eq 0 ]]; then echo "-loglevel quiet"; fi` -i \
                "$i" -f mp3 "$newName" || { exit 1; };
        done

        rm "$dlpath"/*."$1" || { exit 1; };
    fi
}

docreatemeta="0"

all_args=("$@")
dlpath=`pwd`
url="1"
pstart=1
quiet=0
make_pl=1

for ((index=0; index <= "$#"; index++)); do
    arg=${all_args[index]}
    if [[ "$arg" = "-h" ]]; then
        helpAndExit
        exit 0;
    elif [[ "$arg" = "-m" ]]; then
        docreatemeta="1"
    elif [[ "$arg" = "-u" ]]; then
        url="${all_args[++index]}"
    elif [[ "$arg" = "-d" ]]; then
        dlpath="${all_args[++index]}"
    elif [[ "$arg" = "-q" ]]; then
        quiet=1
    elif [[ "$arg" = "-n" ]]; then
        make_pl=0
    fi
done

test -d "$dlpath" || mkdir -p "$dlpath"

if [[ "$url" = "1" ]]; then
    if [ -f "$dlpath"/META.info ];
    then
        url=`cat "$dlpath"/META.info`
    else
        if [[ "$quiet" -eq 0 ]]; then
            echo "Unable to find a META.info file in $dlpath. Please create one with a valid URL in it or specify the URL."
        fi
        invalidArgs
    fi
fi

if [[ "$docreatemeta"  = "1" ]]; then
    if [[ "$quiet" -eq 0 ]]; then
        echo "Writing Metadata file..."
    fi
    touch "$dlpath"/META.info
    echo "$url" > "$dlpath"/META.info
fi

echo "Beginning download"
youtube-dl `if [[ "$quiet" -eq 1 ]]; then echo "-q"; fi` -i -x \
                --download-archive "$dlpath/archive.txt" -o \
                "$dlpath/%(title)s-v=%(id)s.%(ext)s" "$url" # || { exit 1; };

convert m4a
convert opus

if [[ $make_pl -eq 1 ]]; then
    pl_name=$(basename $dlpath)
    ls "$dlpath" | while read line; do echo "$dlpath/$line"; done > $dlpath/$pl_name.m3u
fi

