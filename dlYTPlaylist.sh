#!/bin/bash

function invalidArgs(){
    echo "Invalid number of arguments."
    helpAndExit
}

function helpAndExit(){
    echo "dlYTPlaylist [OPTIONS]"
    echo "    -h       Display this message and exit."
    echo "    -s       Number in the playlist to start with."
    echo "    -m       Create a metadata file which stores the original URL."
    echo "    -u       The URL to use."
    echo "    -d       The directory to save to."
    exit 1;
}

docreatemeta=1

if [[ "$#" -lt 1 ]]; then
    invalidArgs
fi

all_args=("$@")
dlpath=1
url=1

for ((index=0; index <= "$#"; index++)); do
    arg=${all_args[index]}
    if [[ "$arg" = "-h" ]]; then
        helpAndExit
    elif [[ "$arg" = "-s" ]]; then
        if [[ "$#" -lt 4 ]]; then
            invalidArgs
        fi
        pstart="${all_args[++index]}"
    elif [[ "$arg" = "-m" ]]; then
        docreatemeta=0
    elif [[ "$arg" = "-u" ]]; then
        url="${all_args[++index]}"
    elif [[ "$arg" = "-d" ]]; then
        dlpath="${all_args[++index]}"
    fi
done

if [[ "$dlpath" -eq 1 || "$url" -eq 1 ]]; then
    invalidArgs
fi

test -d "$dlpath" || mkdir -p "$dlpath"

echo "Beginning download"
youtube-dl -x --playlist-start "$pstart" -o "$dlpath/%(title)s-%(id)s.%(ext)s" "$url" || { exit 1; };

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

if [[ "$docreatemeta" ]]; then
    echo "Writing Metadata file..."
    touch "$dlpath"/META.info
    echo "$url" > "$dlpath"/META.info
fi
 
