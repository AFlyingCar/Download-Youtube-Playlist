#include <string>
#include <fstream>
#include <iostream>
#include <fts.h>
#include <cstdlib>
#include <cstring>

bool docreatemeta = false;
std::string dlpath = ".";
std::string url = "";
std::fstream meta;

void Usage() {
    std::cout << "dlYTPlaylist [OPTIONS]" << std::endl
              << "    -h       Display this message and exit." << std::endl
              << "    -m       Create a metadata file which stores the "
                 "original URL." << std::endl
              << "    -u [URL] The URL to use." << std::endl
              << "    -d [DIR] The directory to save to." << std::endl;
}

int ffmpeg(std::string file) {
    file = file.substr(0, file.find(".m4a"));
    std::string args = "ffmpeg -i ";
    args += file;
    args += ".m4a -f mp3 ";
    args += file;
    args += ".mp3";
    if(system(args.c_str()) == -2)
        return 1;
    return 0;
}

int FileHelper(int x/*, char * const argv*/) {
    FTS *ftsp;
    FTSENT *p, *chp;
    char *aoeuaoeuoaeuaoeuaoeuaoeu = new char [dlpath.length() + 1];
    std::strcpy(aoeuaoeuoaeuaoeuaoeuaoeu, dlpath.c_str());
    char * const argvs[] = { aoeuaoeuoaeuaoeuaoeuaoeu, NULL };
    int fts_options = FTS_COMFOLLOW | FTS_LOGICAL | FTS_NOCHDIR;
    
    if ((ftsp = fts_open(argvs, fts_options, NULL)) == NULL) {
        return 1;
    }

    chp = fts_children(ftsp, 0);
    if (!chp) {
        return 2;
    }

    std::string file;

    while (p = fts_read(ftsp)) {
        file = p->fts_path;
        switch (p->fts_info) {
            case FTS_D:
                break;
            case FTS_F:
                if (x) {
                    if (ffmpeg(file)) {
                        return 3;
                    }
                } else {
                    if (remove(file.c_str()))
                        return 4;
                }
                break;
            default:
                return 1;
        }
        fts_close(ftsp);
        return 0;
    }
}

void ProcessArg(int i, int argc, char **argv) {
    std::cout << "Processing " << argv[i] << std::endl;
    std::string arg = argv[i];
    if (arg == "-h") {
        std::cout << "Helping" << std::endl;
        Usage();
        std::exit(0);
    }
    if (arg == "-m") {
        std::cout << "Make a META.info" << std::endl;
        docreatemeta = true;
    }
    if (arg == "-u") {
        if (++i < argc) {
            std::cout << "url = `" << argv[i] << "'" << std::endl;
            url = argv[i];
        }
        else {
            throw std::string("Invalid number of arguments.");
        }
    }
    if (arg == "-d") {
        if (++i < argc) {
            std::cout << "directory = `" << argv[i] << "'" << std::endl;
            dlpath = argv[i];
        }
        else {
            throw std::string("Invalid number of arguments.");
        }
    }
}

int main(int argc, char **argv) {
    if (argc == 1) {
        std::cerr << "Invalid number of arguments." << std::endl;
        Usage();
        return 1;
    }

    try {
        for (int i = 1; i < argc; i++) {
            ProcessArg(i, argc, argv);
        }
    } catch (std::string e) {
        std::cerr << e << std::endl;
        Usage();
        return 1;
    }

    if (url == "") {
        meta.open((dlpath + "/META.info").c_str());
        if (meta.is_open()) {
            meta >> url;
        } else if (!docreatemeta) {
            std::cerr << "Unable to find a META.info file in "
                      << dlpath
                      << ". Please create one with a valid URL in it or specify"
                      << " one with the `-u' flag." << std::endl;
            return 1;
        }
        meta.close();
    }

    if (docreatemeta) {
        std::cout << "Writing Metadata file..." << std::endl;
        meta.open((dlpath + "/META.info").c_str());
        if (meta.is_open()) {
            meta << url;
        } else {
            std::cerr << "Unable to open `" << dlpath << "/META.info'."
                      << std::endl;
            return 1;
        }
        meta.close();
    }

    std::cout << "Beginning download" << std::endl;
    std::string args = "youtube-dl -i -x --download-archive \"";
    args += dlpath;
    args += "/archive.txt\" -o \"";
    args += dlpath;
    args += "/%(title)s-v=%(id)s.%(ext)s\" \"";
    args += url;
    args += "\"";
    if (system(args.c_str())) {
        std::cerr << "You have to have youtube-dl installed." << std::endl
                  << "Download it from: https://rg3.github.io/youtube-dl/"
                  << "download.html" << std::endl;
        return 1;
    }

    std::cout << "Converting all files to MP3 format..." << std::endl;
    switch (FileHelper(0/*, argv*/)) {
        case 1:
            std::cerr << "A filesystem error occurred." << std::endl;
            return 1;
        case 2:
            std::cout << "The folder is empty." << std::endl;
            break;
        case 3:
            std::cerr << "You have to have ffmpeg installed." << std::endl;
            return 1;
        default:
            break;
    }

    std::cout << "Cleaning up directory..." << std::endl;
    switch (FileHelper(1/*, argv*/)) {
        case 1:
            std::cerr << "A filesystem error occurred." << std::endl;
            return 1;
        case 2:
            std::cout << "The folder is empty." << std::endl;
            break;
        case 4:
            std::cerr << "An unknown error occurred." << std::endl;
            return 1;
        default:
            break;
    }

    return 0;
}
