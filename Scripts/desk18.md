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
* docker - lightweight virtualization (works in a vm)

The install script is [desk18.sh](desk18.sh) which CS faculty are welcome to contribute to or suggest changes.

# VMWare Install (Fusion)

Create a base image
- (+) new VM
- install from image (first big button)
- Choose ubuntu-18.04.5-desktop-amd64.iso, "continue"
- "use easy install", Display Name: mav, user: mav, password: rick, "continue"
- "cusomize settings" save as "desk18"
- notes: mav/rick, HDD: 120GB, USB: 3.1, Enable Hypervisor
- hdd: 120GB
- USB: 3.1
- Hardware Version: 14
- Boot
- after install shutdown, save snapshop "base"
wget https://raw.githubusercontent.com/coloradomesa/cs-labs-public/master/Scripts/desk18.sh
bash desk18.sh start ...
- shutdown
- save as snapshot

---
For Virtual Box see the google Doc [Installing Ubuntu 18.04 Desktop in VirtualBox at Colorado Mesa](https://docs.google.com/document/d/1kmjY_8B1UuRr4IMsJefEGnq92zuq7Y9UJCvUJeIj94A/edit#)
  