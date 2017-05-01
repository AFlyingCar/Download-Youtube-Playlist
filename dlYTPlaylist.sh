#!/bin/bash

function invalidArgs(){
    echo "Invalid number of arguments."
    helpAndExit
    exit 1;
}

function helpAndExit(){
    echo "dlYTPlaylist [OPTIONS]"
    echo "    -h       Display this message and exit."
    echo "    -m       Create a metadata file which stores the original URL."
    echo "    -u [URL] The URL to use."
    echo "    -d [DIR] The directory to save to."
}

docreatemeta="0"

all_args=("$@")
dlpath=`pwd`
url="1"
pstart=1

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
    fi
done

test -d "$dlpath" || mkdir -p "$dlpath"

if [[ "$url" = "1" ]]; then
    if [ -f "$dlpath"/META.info ];
    then
        url=`cat "$dlpath"/META.info`
    else
        echo "Unable to find a META.info file in $dlpath. Please create one with a valid URL in it or specify the URL."
        invalidArgs
    fi
fi

if [[ "$docreatemeta"  = "1" ]]; then
    echo "Writing Metadata file..."
    touch "$dlpath"/META.info
    echo "$url" > "$dlpath"/META.info
fi

echo "Beginning download"
youtube-dl -i -x --download-archive "$dlpath/archive.txt" -o "$dlpath/%(title)s-v=%(id)s.%(ext)s" "$url" # || { exit 1; };

if [[ `ls "$dlpath"/*.m4a -1 2>/dev/null | wc -l` != 0 ]]; then
    echo "Converting all m4a files to mp3 format..."
    for i in "$dlpath"/*.m4a; do
        newName=`echo "$i" | sed -e 's/m4a/mp3/'` || { exit 1; };
        ffmpeg -i "$i" -f mp3 "$newName" || { exit 1; };
    done
fi

if [[ `ls "$dlpath"/*.m4a -1 2>/dev/null | wc -l` != 0 ]]; then
    rm "$dlpath"/*.m4a || { exit 1; };
fi

