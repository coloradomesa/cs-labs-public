#!/bin/bash

if ! sudo -v
then
    echo $USER cannot execute sudo - please use an admin user account
    exit 1
fi
config_dir="$HOME/.config/cs.coloradomesa.edu"
state_file="$config_dir/state.txt"
script_file="$config_dir/desk18.sh"
script_backup="$config_dir/desk18.sh-"
script_git="https://raw.githubusercontent.com/coloradomesa/cs-labs-public/master/Scripts/desk18.sh"

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
    set_state reload
}

function state_reload() {
    wget -O "$script_backup" "$script_git"
    ok=false
    if [ -f "$script_file" ]
    then
	if diff -q "$script_file" "$script_backup"
	then
	    ok=true
	fi
    fi

    set_state base_install

    if [ "$ok" != "true" ]
    then
	echo "new version found, restarting..."
	cp "$script_backup" "$script_file"
	exec /bin/bash -x "$script_file" "$@"
    fi
}

function state_base_install() {
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
    sudo snap install code --classic
    set_state lxd
}

function state_lxd() {
    local preseed="$HOME/.config/cs.coloradomesa.edu/lxd.preseed.txt"
    cat >"$preseed" <<EOF
config: {}
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: ""
  managed: false
  name: lxdbr0
  type: ""
storage_pools:
- config:
    size: 15GB
  description: ""
  name: default
  driver: zfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
EOF
  sudo lxd init --preseed "$preseed"
  set_state docker
}

function state_docker() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
    sudo apt update
    sudo apt install -y docker-ce
    set_state halt
}

if [ $# -gt 0 ]
then
    for state in "$@"
    do
	if [ "$state" = "..." ]
	then
	    break
	fi
	set_state "$state"
	state_$state
    done
    if [ "$state" != "..." ]
    then
	exit 0
    fi
fi

while true
do
    state=$(get_state)
    if [ $state = halt ] ; then break ; fi
    state_$state
done
