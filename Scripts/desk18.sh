#!/bin/bash

if ! sudo -v
then
    echo $USER cannot execute sudo - please use an admin user account
    exit 1
fi
config_dir="$HOME/.config/cs.coloradomesa.edu"
mkdir -p "$config_dir"
state_file="$config_dir/state.txt"
script_file="$config_dir/desk18.sh"
script_backup="$config_dir/desk18.sh-"
script_git="https://raw.githubusercontent.com/coloradomesa/cs-labs-public/master/Scripts/desk18.sh"

function add_ppa_if_not_exist() {
# https://askubuntu.com/questions/381152/how-to-check-if-ppa-is-already-added-to-apt-sources-list-in-a-bash-script
    local ppa
    local update
    update=false
    for ppa in "$@"
    do
	if ! egrep -q "^deb .*$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*
	then
	    sudo add-apt-repository -y ppa:"$ppa"
	    update=true
	fi
    done
    if [ $update = true ]
    then
	sudo apt update
    fi
fi
}

wget -O "$script_backup" "$script_git"
ok=false
if [ -f "$script_file" ]
then
    if diff -q "$script_file" "$script_backup"
    then
	ok=true
    fi
fi

if [ "$ok" != "true" ]
then
    echo "new version found, restarting..."
    cp "$script_backup" "$script_file"
    sleep 4
    exec /bin/bash -x "$script_file" "$@"
fi

while ! sudo apt update
do
    echo "waiting 10 seconds to retry..."
    sleep 10
done

while ! sudo apt upgrade -y
do
    echo "waiting 10 seconds to retry..."
    sleep 10
done

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
    set_state base_install
}

function state_base_install() {
    sudo apt install -y rng-tools virt-what

    if sudo virt-what | grep virtualbox
    then
	sudo apt install -y virtualbox-guest-dkms
    fi

    if sudo virt-what | grep vmware
    then
	sudo apt install -y -o Dpkg::Options::=--force-confnew \
	    open-vm-tools-desktop
    fi

    sudo apt install -y \
	apt-transport-https \
	build-essential \
	ca-certificates \
	curl \
	emacs \
	git \
	openssh-server \
	software-properties-common \
	vim \
	# eol
    set_state kivy
}

function state_kivy() {
    if ! cat /etc/apt/sources.list /etc/apt/sources.list.d/* | egrep "^deb .*/kivy-team/kivy/"
    then
	sudo add-apt-repository -y ppa:kivy-team/kivy
	sudo apt-get update
    fi
    sudo apt install -y kivy
    set_state chrome
}

function state_chrome() {
    if ! dpkg-query -W -f='${Status} ${Version}\n' google-chrome-stable | grep -q "install ok"
    then
	pushd "$HOME/Downloads"
	if [ ! -f google-chrome-stable_current_amd64.deb ]
	then
	    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb 
	fi
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	popd
    fi
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
    if !lxc profile device list default | grep -q "eth0"
    then
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
	sudo snap install lxd
	sudo lxd init --preseed <"$preseed"
	sudo adduser $USER lxd
    fi
    
    set_state docker
}

function state_docker() {
    if ! apt-key list | grep docker 
    then
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    fi
    
    local deb
    deb="deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
    if ! cat /etc/apt/sources.list /etc/apt/sources.list.d/* | egrep "^$deb"
    then
	sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
	sudo apt update
    fi
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
