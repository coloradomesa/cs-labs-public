#!/bin/bash

if ! sudo -v
then
    echo $USER cannot execute sudo - please use an admin user account
    exit 1
fi

state_file="$HOME/.config/cs.coloradomesa.edu/state.txt"

function set_state() {
    if [ ! -w $state_file ]
    then
	mkdir -p "$(dirname "$state_file")"
    fi
    echo "$1" > "$state_file"
}

function get_state() {
    test -r "$state_file" && cat "$state_file" || echo "start"
}

function state_start() {
    set_state chrome
}

function state_chrome() {
    pushd "$HOME/Downloads"
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
    sudo dpkg -i google-chrome-stable_current_amd64.deb
    popd
    set_state install
}


function state_install() {
    sudo apt install -y rng-tools

    sudo apt install -y \
	apt-transport-https \
	build-essential \
	ca-certificates \
	curl \
	emacs \
	git \
	openssh-server \
	open-vm-tools-desktop \
	software-properties-common \
	vim \
	# eol

    sudo apt install -y \
	codeblocks \
	cmake \
	clang \
	default-jdk \
	geany \
	inkscape \
	pylint3 \
	wxmaxima \
	xclip \
	# eol

    sudo snap install netbeans --classic
    sudo snap install gimp
    sudo snap install vlc
    sudo snap install conda --beta    
    sudo snap install octave --beta
    sudo snap install vscode --classic
    sudo snap install lxd
    set_state docker
}

function state_docker() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
    sudo apt update
    sudo apt install -y docker-ce
    set_state halt
}

while true
do
    state=$(get_state)
    if [ $state = halt ] ; then break ; fi
    state_$state
done
