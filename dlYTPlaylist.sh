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

echo "Converting all files to wav format..."
for i in "$dlpath"/*.m4a; do 
    mplayer -ao pcm "$i" -ao pcm:file="$i.wav" || { exit 1; }; 
done

echo "Converting all files to mp3 format..."
for i in "$dlpath"/*.wav; do
    lame -h -b 192 "$i" "$i.mp3" || { exit 1; };
done

echo "Cleaning up directory..."
for i in "$dlpath"/*.mp3; do
    x=`echo "$i"|sed -e 's/m4a.wav.mp3/mp3/'` || { exit 1; };
    mv -u "$i" "$x".tmp || { exit 1; };
    mv -u "$x".tmp "$x" || { exit 1; };
done

rm "$dlpath"/*.m4a || { exit 1; };
rm "$dlpath"/*.m4a.wav || { exit 1; };

