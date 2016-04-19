#!/bin/bash

function invalidArgs(){
    echo "Invalid number of arguments."
    helpAndExit
}

function helpAndExit(){
    echo "dlYTPlaylist [OPTIONS] ... [SAVE DIRECTORY] ... [URL]"
    echo "    -h       Display this message and exit"
    echo "    -s       Number in the playlist to start with"
    exit 1;
}

if [[ "$#" -lt 1 ]]; then
    invalidArgs
elif [[ "$1" = "-h" ]]; then
    helpAndExit
elif [[ "$1" = "-s" ]]; then
    if [[ "$#" -lt 4 ]]; then
        invalidArgs
    fi
    pstart="$2"
    dlpath="$3"
    url="$4"
else
    pstart=1
    dlpath="$1"
    url="$2"
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

# TODO: Add metaData file (holds Playlist URL)
 
