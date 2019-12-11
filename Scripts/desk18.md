#desk18 vm

The desk18 script is intended to install the following software inside an ubuntu 18.04 image:

* rng-tools - fix entropy pool
* virtualbox-guest (for virtualbox) - better host integration for vbox
* open-vm-tools (for vmware) - better host integration for vmware
* apt-transport-https - access to repositories via https
* build-essential - c++ etc
* ca-certificates - extended repository access
* cifs-utils - smb mount campus filesystems (F drive etc)
* curl - command line web tool
* emacs - edtior
* git - version control
* openssh-server - remote accesss
* software-properties-common - software package management
* vim - editor
* mav_mount - mount campus shares (~/bin/mav_mount mounts all campus share folders)
* fix ubuntu bell so it is not so annoying
* gstreamer - add various codecs
* chrome - google chrome browser
* audacity - audio editor
* codeblocks - ide
* cmake - c++ build tool
* clang - llvm compiler (in addition to gcc)
* default-jdk - openjdk 11
* inkscape - vector graphics editor
* maven - java build tool
* python3 - prefer anaconda if any package install is required
* wxmaxima - computer algebra system
* xclip - command line clipping tool
* netbeans - java IDE
* gimp - bitmap graphics editor
* vlc - media player
* octave - matlab clone
* code - visual studio code
* node - nodejs 10
* anaconda - python/node/r virtual environments
* anaconda - py prebuilt py3 venv (conda activate py)
* anaconda - js prebuilt node venv (conda activate js)
* anaconda - cpp prebuilt c++ venv (conda activate cpp)
* wine - windows emulation layer
* docker - lightweight virtualization (works in a vm)

The install script is [desk18.sh](desk18.sh) which CS faculty are welcome to contribute to or suggest changes.