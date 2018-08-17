# Get all parameters from the command line
#
# -h       -- Print help message and exit
# -m       -- Create metadata file
# -u [URL] -- Set YT url to use
# -d [DIR] -- Set save directory
# -q       -- Suppress output
# -n       -- Does not generate an m3u playlist file.
Param(
    [Parameter(HelpMessage="Print help message and exit.")]
        [alias("h")]
        [switch]$Help,
    [Parameter(HelpMessage="Create a metadata file which stores the original URL.")]
        [alias("m")]
        [switch]$CreateMetaFile,
    [Parameter(HelpMessage="Set the URL to download from.")]
        [alias("u")]
        [string]$URL,
    [Parameter(HelpMessage="Set the directory to save the playlist to.")]
        [alias("d")]
        [string]$Directory=(Resolve-Path .\).Path,
    [Parameter(HelpMessage="Suppress all output.")]
        [alias("q")]
        [switch]$Quiet=$false,
    [Parameter(HelpMessage="Does not generate an m3u playlist file.")]
        [alias("n")]
        [switch]$NoPlaylist=$true
)

function invalidArgs() {
    if(!$Quiet) {
        Write-Host "Invalid number of arguments."
    }

    helpMessage
    exit 1
}

function helpMessage() {
    if(!$Quiet) {
        Write-Host "dlYTPlaylist [OPTIONS]"
        Write-Host "    -h       Display this message and exit."
        Write-Host "    -m       Create a metadata file which stores the original URL."
        Write-Host "    -u [URL] The URL to use."
        Write-Host "    -d [DIR] The directory to save to."
        Write-Host "    -q       Suppresses all output."
    }
}

function convert() {
    Param(
        [Parameter(Mandatory=$true)][string]$Type
    )

    files = Get-ChildItem $Directory -Filter *$Type ? { !$_.PSIsContainer }

    if(!$Quiet) {
        Write-Host "Converting all $Type files to mp3 format..."
    }

    foreach($i in $files) {
        newname=($i -replace "$Type","mp3")

        ffmpeg (&{If($Quiet) { "-loglevel quiet" }}) -i "$i" -f mp3 "$newname"
    }

    Remove-Item $Directory/*.$Type
}

function verifyInstall() {
    if((Get-Command "youtube-dl" -ErrorAction SilentlyContinue) -eq $null -or
       (Get-Command "ffmpeg.exe" -ErrorAction SilentlyContinue) -eq $null)
    {
        $Host.UI.WriteErrorLine("This script requires both youtube-dl and ffmpeg to be installed and in the PATH environment variable.")
        $Host.UI.WriteErrorLine("Please make sure that they are installed properly before continuing:")
        $Host.UI.WriteErrorLine("  youtube-dl -- https://rg3.github.io/youtube-dl/")
        $Host.UI.WriteErrorLine("  ffmpeg     -- https://www.ffmpeg.org/")
        exit 1
    }
}

verifyInstall

if($Help) {
    helpMessage
    exit
}

# Create the path if it does not currently exist
if(!(Test-Path -Path $Directory)) {
    New-Item -ItemType directory -Path $Directory
}

# If no url was given, see if we can find one in a meta file
if($URL -eq "") {
    if(Test-Path -Path $Directory/META.info) {
        URL=(Get-Content -Path $Directory/META.info)
    } else {
        if(!$Quiet) {
            Write-Host "Unable to find a META.info file in $Directory. Please create one with a valid URL in it or specify the URL with -URL or -u."
        }
        invalidArgs
    }
}

if($CreateMetaFile) {
    if(!$Quiet) {
        Write-Host "Writing Metadata file."
    }
    Out-File -FilePath $Directory/META.info -InputObject $URL -Encoding ASCII
}

if(!$Quiet) {
    Write-Host "Beginning download."
}

youtube-dl (&{If($Quiet) { "-q" }}) -i -x --download-archive "$Directory/archive.txt" -o "$Directory/%(title)s-v=%(id)s.%(ext)s" "$URL"

convert m4a
convert opus

# TODO: Uncomment this when testing on Windows
# if(!$NoPlaylist) {
#     Out-File -FilePath $Directory/playlist.m3u
#              -InputObject Get-ChildItem "$Directory" -Filter *.mp3 *.ogg | Foreach-Object
#     {
#         $OutputPath = Get-Content $_.FullName
#         $content = Split-Path $OutputPath.FullName -leaf
#     } -Encoding ASCII
# }
