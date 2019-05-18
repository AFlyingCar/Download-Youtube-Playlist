#!/bin/bash

function invalidArgs(){
    echo "Invalid number of arguments." >&2
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
        echo "    -q       Suppresses all standard output."
        echo "    -n       Does not generate an m3u playlist file."
        echo "    -v       Enables verbose output."
        echo "    -s       Perform a dry run, do not download anything or touch the disk."
        echo "    -Q       Suppresses all notifications and beeps."
        echo "    -B       Suppresses beeps."
        echo "    -N       Suppresses notifications."
    fi
}

function convert(){
    if [[ `ls "$dlpath"/*."$1" -1 2>/dev/null | wc -l` != 0 ]]; then
        if [[ "$quiet" -eq 0 ]]; then
            echo "Converting all $1 files to mp3 format..."
        fi

        for i in "$dlpath"/*."$1"; do
            newName=`echo "$i" | sed -e "s/$1/mp3/"` || { exit 1; };
            ffmpeg `if [[ "$quiet" -eq 0 ]]; then echo "-loglevel quiet"; fi` \
                   `if [[ "$verbose" -eq 1 ]]; then echo "-loglevel verbose"; fi` \
                   -i "$i" -f mp3 "$newName" || { exit 1; };
        done

        rm "$dlpath"/*."$1" || { exit 1; };
    fi
}

function verifyInstall() {
    ytdl_verify=0
    ffmpeg_verify=0
    command -v youtube-dl >/dev/null 2>&1 || {
        ytdl_verify=1
    }
    command -v ffmpeg >/dev/null 2>&1 || {
        ffmpeg_verify=1
    }

    if [ $ytdl_verify -eq 1 ] || [ $ffmpeg_verify -eq 1 ]; then
        echo "This script requires both youtube-dl and ffmpeg to be installed and in the PATH environment variable." >&2
        echo "Please make sure that they are installed properly before continuing:" >&2
        echo "  youtube-dl -- https://rg3.github.io/youtube-dl/" >&2
        echo "  ffmpeg     -- https://www.ffmpeg.org/" >&2
        exit 1
    fi
}

can_beep=1
can_notify=1

function verifyNonEssentials() {
    command -v beep >/dev/null 2>&1 || {
        can_beep=0
    }
    command -v notify-send>/dev/null 2>&1 || {
        can_notify=0
    }
}

verifyInstall
verifyNonEssentials

docreatemeta="0"

all_args=("$@")
dlpath=`pwd`
url="1"
pstart=1
quiet=0
make_pl=1
verbose=0
isdry=0

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
    elif [[ "$arg" = "-v" ]]; then
        verbose=1
    elif [[ "$arg" = "-s" ]]; then
        isdry=1
    elif [[ "$arg" = "-Q" ]]; then
        can_notify=0
        can_beep=0
    elif [[ "$arg" = "-N" ]]; then
        can_notify=0
    elif [[ "$arg" = "-B" ]]; then
        can_beep=0
    fi
done

test -d "$dlpath" || mkdir -p "$dlpath"

if [[ "$url" = "1" ]]; then
    if [ -f "$dlpath"/META.info ];
    then
        url=`cat "$dlpath"/META.info`
    else
        echo "Unable to find a META.info file in $dlpath. Please create one with a valid URL in it or specify the URL." >&2
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

if [[ "$quiet" -eq 0 ]]; then
    echo "Beginning download"
fi

if [[ "$isdry" -eq 0 ]]; then
    youtube-dl `if [[ "$quiet" -eq 1 ]]; then echo "-q"; fi` \
               `if [[ "$verbose" -eq 1 ]]; then echo "--verbose"; fi` -i -x \
               --download-archive "$dlpath/archive.txt" -o \
               "$dlpath/%(title)s-v=%(id)s.%(ext)s" "$url" # || { exit 1; };

    convert m4a
    convert opus
fi

if [[ $make_pl -eq 1 ]]; then
    pl_name=$(basename $dlpath)
    ls "$dlpath" | while read line; do echo "$dlpath/$line"; done > $dlpath/$pl_name.m3u

fi

if [[ "$can_notify" -eq 1 ]]; then
    notify-send --urgency=low "$(basename "$0"): Download Complete"
fi

if [[ "$can_beep" -eq 1 ]]; then
    beep -f 750 -n -f 1000
fi

