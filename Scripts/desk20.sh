#!/bin/bash

if ! sudo -v
then
    echo $USER cannot execute sudo - please use an admin user account
    exit 1
fi
config_dir="$HOME/.config/cs.coloradomesa.edu"
mkdir -p "$config_dir"
state_file="$config_dir/state.txt"
script_file="$config_dir/desk20.sh"
script_backup="$config_dir/desk20.sh-"
script_git="https://raw.githubusercontent.com/coloradomesa/cs-labs-public/master/Scripts/desk20.sh"

# download latest version and restart if different
/bin/rm -rf "$script_backup"
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
    sleep 2
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
    if ! sudo apt install -y rng-tools virt-what
    then
        exit 1
    fi

    if sudo virt-what | grep virtualbox
    then
        sudo apt install -y virtualbox-guest-dkms
    fi

    if sudo virt-what | grep vmware
    then
        sudo apt install -y -o Dpkg::Options::=--force-confnew \
            open-vm-tools-desktop
    fi

    if ! sudo apt install -y \
        apt-transport-https \
        build-essential \
        ca-certificates \
        cifs-utils \
        curl \
        emacs \
        git \
        openssh-server \
        software-properties-common \
        vim \
        # eol
    then
        exit 1
    fi

#
# clones would have duplicate keys...
#
#    if [ ! -f ~/.ssh/id_rsa ]
#    then
#        /bin/rm -rf ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
#        ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa
#    fi
#
    set_state mav_mount
}

function state_mav_mount() {
    mkdir -p ~/bin
    cat >~/bin/mav_mount <<'EOF'
#!/bin/bash
if [ "$MAV_USER" = "" ]
then
    echo -n "mav username: "
    read MAV_USER
fi

if [ "$MAV_PASS" = "" ]
then
    echo -n "password: "
    read -s MAV_PASS
fi

if apt-cache policy cifs-utils | grep -q "Installed: (none)"
then
    echo "installing missing cifs tools..."
    sudo apt install -y cifs-utils
fi

if ! timeout 4 ping -c 1 homefs.coloradomesa.edu >/dev/null
then
  echo "cannot access Colorado Mesa share folders."
  exit 1
fi


for locmnt in \
    $HOME/cmu/f://homefs.coloradomesa.edu/Home/$MAV_USER \
    $HOME/cmu/k://homefs.coloradomesa.edu/courses \
    $HOME/cmu/r://sharefs.coloradomesa.edu/share \
    $HOME/cmu/s://sharefs.coloradomesa.edu/share3 \
    #eol
do
  loc=${locmnt%%:*}
  mnt=${locmnt#*:}
  host=${mnt#//}
  host=${host%%/*}
  sudo umount $loc 2>/dev/null
  sudo mkdir -p $loc
  sudo mount -t cifs -o username="$MAV_USER",password="$MAV_PASS",uid="$(id -u)",gid="$(id -g)",forceuid,forcegid $mnt $loc
done
EOF
chmod +x ~/bin/mav_mount
set_state bell
}

function state_bell() {
    # awful bell sound becomes a click sound
    base64 --decode >"$config_dir/bell.ogg" <<EOF
T2dnUwACAAAAAAAAAADEa2ckAAAAACYsS1wBHgF2b3JiaXMAAAAAAYC7AAAAAAAAAHcBAAAAAAC4AU9nZ1MAAAAAAAAAAAAAxGtnJAEAAAB7qBqjEDv//////////////////8kDdm9yYmlzKwAAAFhpcGguT3JnIGxpYlZvcmJpcyBJIDIwMTIwMjAzIChPbW5pcHJlc2VudCkAAAAAAQV2b3JiaXMpQkNWAQAIAAAAMUwgxYDQkFUAABAAAGAkKQ6TZkkppZShKHmYlEhJKaWUxTCJmJSJxRhjjDHGGGOMMcYYY4wgNGQVAAAEAIAoCY6j5klqzjlnGCeOcqA5aU44pyAHilHgOQnC9SZjbqa0pmtuziklCA1ZBQAAAgBASCGFFFJIIYUUYoghhhhiiCGHHHLIIaeccgoqqKCCCjLIIINMMumkk0466aijjjrqKLTQQgsttNJKTDHVVmOuvQZdfHPOOeecc84555xzzglCQ1YBACAAAARCBhlkEEIIIYUUUogppphyCjLIgNCQVQAAIACAAAAAAEeRFEmxFMuxHM3RJE/yLFETNdEzRVNUTVVVVVV1XVd2Zdd2ddd2fVmYhVu4fVm4hVvYhV33hWEYhmEYhmEYhmH4fd/3fd/3fSA0ZBUAIAEAoCM5luMpoiIaouI5ogOEhqwCAGQAAAQAIAmSIimSo0mmZmquaZu2aKu2bcuyLMuyDISGrAIAAAEABAAAAAAAoGmapmmapmmapmmapmmapmmapmmaZlmWZVmWZVmWZVmWZVmWZVmWZVmWZVmWZVmWZVmWZVmWZVmWZVlAaMgqAEACAEDHcRzHcSRFUiTHciwHCA1ZBQDIAAAIAEBSLMVyNEdzNMdzPMdzPEd0RMmUTM30TA8IDVkFAAACAAgAAAAAAEAxHMVxHMnRJE9SLdNyNVdzPddzTdd1XVdVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVgdCQVQAABAAAIZ1mlmqACDOQYSA0ZBUAgAAAABihCEMMCA1ZBQAABAAAiKHkIJrQmvPNOQ6a5aCpFJvTwYlUmye5qZibc84555xszhnjnHPOKcqZxaCZ0JpzzkkMmqWgmdCac855EpsHranSmnPOGeecDsYZYZxzzmnSmgep2Vibc85Z0JrmqLkUm3POiZSbJ7W5VJtzzjnnnHPOOeecc86pXpzOwTnhnHPOidqba7kJXZxzzvlknO7NCeGcc84555xzzjnnnHPOCUJDVgEAQAAABGHYGMadgiB9jgZiFCGmIZMedI8Ok6AxyCmkHo2ORkqpg1BSGSeldILQkFUAACAAAIQQUkghhRRSSCGFFFJIIYYYYoghp5xyCiqopJKKKsoos8wyyyyzzDLLrMPOOuuwwxBDDDG00kosNdVWY4215p5zrjlIa6W11lorpZRSSimlIDRkFQAAAgBAIGSQQQYZhRRSSCGGmHLKKaegggoIDVkFAAACAAgAAADwJM8RHdERHdERHdERHdERHc/xHFESJVESJdEyLVMzPVVUVVd2bVmXddu3hV3Ydd/Xfd/XjV8XhmVZlmVZlmVZlmVZlmVZlmUJQkNWAQAgAAAAQgghhBRSSCGFlGKMMcecg05CCYHQkFUAACAAgAAAAABHcRTHkRzJkSRLsiRN0izN8jRP8zTRE0VRNE1TFV3RFXXTFmVTNl3TNWXTVWXVdmXZtmVbt31Ztn3f933f933f933f933f13UgNGQVACABAKAjOZIiKZIiOY7jSJIEhIasAgBkAAAEAKAojuI4jiNJkiRZkiZ5lmeJmqmZnumpogqEhqwCAAABAAQAAAAAAKBoiqeYiqeIiueIjiiJlmmJmqq5omzKruu6ruu6ruu6ruu6ruu6ruu6ruu6ruu6ruu6ruu6ruu6ruu6QGjIKgBAAgBAR3IkR3IkRVIkRXIkBwgNWQUAyAAACADAMRxDUiTHsixN8zRP8zTREz3RMz1VdEUXCA1ZBQAAAgAIAAAAAADAkAxLsRzN0SRRUi3VUjXVUi1VVD1VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVXVNE3TNIHQkJUAABkAACNBBhmEEIpykEJuPVgIMeYkBaE5BqHEGISnEDMMOQ0idJBBJz24kjnDDPPgUigVREyDjSU3jiANwqZcSeU4CEJDVgQAUQAAgDHIMcQYcs5JyaBEzjEJnZTIOSelk9JJKS2WGDMpJaYSY+Oco9JJyaSUGEuKnaQSY4mtAACAAAcAgAALodCQFQFAFAAAYgxSCimFlFLOKeaQUsox5RxSSjmnnFPOOQgdhMoxBp2DECmlHFPOKccchMxB5ZyD0EEoAAAgwAEAIMBCKDRkRQAQJwDgcCTPkzRLFCVLE0XPFGXXE03XlTTNNDVRVFXLE1XVVFXbFk1VtiVNE01N9FRVE0VVFVXTlk1VtW3PNGXZVFXdFlXVtmXbFn5XlnXfM01ZFlXV1k1VtXXXln1f1m1dmDTNNDVRVFVNFFXVVFXbNlXXtjVRdFVRVWVZVFVZdmVZ91VX1n1LFFXVU03ZFVVVtlXZ9W1Vln3hdFVdV2XZ91VZFn5b14Xh9n3hGFXV1k3X1XVVln1h1mVht3XfKGmaaWqiqKqaKKqqqaq2baqurVui6KqiqsqyZ6qurMqyr6uubOuaKKquqKqyLKqqLKuyrPuqLOu2qKq6rcqysJuuq+u27wvDLOu6cKqurquy7PuqLOu6revGceu6MHymKcumq+q6qbq6buu6ccy2bRyjquq+KsvCsMqy7+u6L7R1IVFVdd2UXeNXZVn3bV93nlv3hbJtO7+t+8px67rS+DnPbxy5tm0cs24bv637xvMrP2E4jqVnmrZtqqqtm6qr67JuK8Os60JRVX1dlWXfN11ZF27fN45b142iquq6Ksu+sMqyMdzGbxy7MBxd2zaOW9edsq0LfWPI9wnPa9vGcfs64/Z1o68MCcePAACAAQcAgAATykChISsCgDgBAAYh5xRTECrFIHQQUuogpFQxBiFzTkrFHJRQSmohlNQqxiBUjknInJMSSmgplNJSB6GlUEproZTWUmuxptRi7SCkFkppLZTSWmqpxtRajBFjEDLnpGTOSQmltBZKaS1zTkrnoKQOQkqlpBRLSi1WzEnJoKPSQUippBJTSam1UEprpaQWS0oxthRbbjHWHEppLaQSW0kpxhRTbS3GmiPGIGTOScmckxJKaS2U0lrlmJQOQkqZg5JKSq2VklLMnJPSQUipg45KSSm2kkpMoZTWSkqxhVJabDHWnFJsNZTSWkkpxpJKbC3GWltMtXUQWgultBZKaa21VmtqrcZQSmslpRhLSrG1FmtuMeYaSmmtpBJbSanFFluOLcaaU2s1ptZqbjHmGlttPdaac0qt1tRSjS3GmmNtvdWae+8gpBZKaS2U0mJqLcbWYq2hlNZKKrGVklpsMebaWow5lNJiSanFklKMLcaaW2y5ppZqbDHmmlKLtebac2w19tRarC3GmlNLtdZac4+59VYAAMCAAwBAgAlloNCQlQBAFAAAQYhSzklpEHLMOSoJQsw5J6lyTEIpKVXMQQgltc45KSnF1jkIJaUWSyotxVZrKSm1FmstAACgwAEAIMAGTYnFAQoNWQkARAEAIMYgxBiEBhmlGIPQGKQUYxAipRhzTkqlFGPOSckYcw5CKhljzkEoKYRQSiophRBKSSWlAgAAChwAAAJs0JRYHKDQkBUBQBQAAGAMYgwxhiB0VDIqEYRMSiepgRBaC6111lJrpcXMWmqttNhACK2F1jJLJcbUWmatxJhaKwAA7MABAOzAQig0ZCUAkAcAQBijFGPOOWcQYsw56Bw0CDHmHIQOKsacgw5CCBVjzkEIIYTMOQghhBBC5hyEEEIIoYMQQgillNJBCCGEUkrpIIQQQimldBBCCKGUUgoAACpwAAAIsFFkc4KRoEJDVgIAeQAAgDFKOQehlEYpxiCUklKjFGMQSkmpcgxCKSnFVjkHoZSUWuwglNJabDV2EEppLcZaQ0qtxVhrriGl1mKsNdfUWoy15pprSi3GWmvNuQAA3AUHALADG0U2JxgJKjRkJQCQBwCAIKQUY4wxhhRiijHnnEMIKcWYc84pphhzzjnnlGKMOeecc4wx55xzzjnGmHPOOeccc84555xzjjnnnHPOOeecc84555xzzjnnnHPOCQAAKnAAAAiwUWRzgpGgQkNWAgCpAAAAEVZijDHGGBsIMcYYY4wxRhJijDHGGGNsMcYYY4wxxphijDHGGGOMMcYYY4wxxhhjjDHGGGOMMcYYY4wxxhhjjDHGGGOMMcYYY4wxxhhjjDHGGGOMMcYYW2uttdZaa6211lprrbXWWmutAEC/CgcA/wcbVkc4KRoLLDRkJQAQDgAAGMOYc445Bh2EhinopIQOQgihQ0o5KCWEUEopKXNOSkqlpJRaSplzUlIqJaWWUuogpNRaSi211loHJaXWUmqttdY6CKW01FprrbXYQUgppdZaiy3GUEpKrbXYYow1hlJSaq3F2GKsMaTSUmwtxhhjrKGU1lprMcYYay0ptdZijLXGWmtJqbXWYos11loLAOBucACASLBxhpWks8LR4EJDVgIAIQEABEKMOeeccxBCCCFSijHnoIMQQgghREox5hx0EEIIIYSMMeeggxBCCCGEkDHmHHQQQgghhBA65xyEEEIIoYRSSuccdBBCCCGUUELpIIQQQgihhFJKKR2EEEIooYRSSiklhBBCCaWUUkoppYQQQgihhBJKKaWUEEIIpZRSSimllBJCCCGUUkoppZRSQgihlFBKKaWUUkoIIYRSSimllFJKCSGEUEoppZRSSikhhBJKKaWUUkoppQAAgAMHAIAAI+gko8oibDThwgNQaMhKAIAMAABx2GrrKdbIIMWchJZLhJByEGIuEVKKOUexZUgZxRjVlDGlFFNSa+icYoxRT51jSjHDrJRWSiiRgtJyrLV2zAEAACAIADAQITOBQAEUGMgAgAOEBCkAoLDA0DFcBATkEjIKDArHhHPSaQMAEITIDJGIWAwSE6qBomI6AFhcYMgHgAyNjbSLC+gywAVd3HUghCAEIYjFARSQgIMTbnjiDU+4wQk6RaUOAgAAAADgAAAeAACSDSAiIpo5jg6PD5AQkRGSEpMTlAAAAAAAsAGADwCAJAWIiIhmjqPD4wMkRGSEpMTkBCUAAAAAAAAAAAAICAgAAAAAAAQAAAAICE9nZ1MABL8LAAAAAAAAxGtnJAIAAABVz728CCW4KDAvMMC3fC3FBoD4cOZ9lQIj4dDj1zK4QteNOGA1W5TVvIhKgwoqEyi9AFKFpGiMCgMJI5q+F0e0/fmd3iR5YKyAznuOWTBg2E0PDj+yM4W591uz8ZhpI/nr3YVN+5PSWN1Um6NIHe9Cm4FIa+LK+P5vuNbnDq/nYFCxTnkMxdxhCpHhV1JJgUu7/EStKt97NWYctIvraXZdKAOmES42pxphDJ+Q3pUJtdK8RnZo4cmaVqMVmig6TozdRd4SpvfFhPHNbe/mHOuzpoJd0d/ikLWrXQ/61gNSCvZBMpxHMLY0ah2cNckATsQPDjknQAaByz56NsgwBw909saH5xamWnNHn9z+hTRbmfADnDF1i7Ea0e6aihs9Yf9VAHdm4v3EbrjwrwW2fWH9bTestEp7JCOrdEtfKgz3ZowGfDXLK8+w1vCXbi5Y0b6INDDrz/+19ot99GsaPxO2oK3ZgwcCUlLvvFoNp45k1gakMXewBFtjxB9LQbE/MsJnM3MTp2RusnJU/jjicaxrZalMQXK+gtnrw+DIfox5GwH6hRyuxD74aFzRGt/lsTRt+jor4rWjvs2wUQVMqly2ZlkwU+wLhvONz75W/qZNpk6CHPXf5W3jjPJocW3EpEnMgm+rhvchDOahgdu5p93aANrqSyiZNbXFvwt8zLygNlNDz6jAcbp1JP/lRBeeFgfV5f+QoCAz83p+1jDIN8iRgM/+cMVCX07dz8/um9az+6WhsIzN7c9emCSEhaRxDBcZeH4uWjFYUoEa+qiJgTBNqfYgG2i32taY1Jv/gM4moAD+hURojavhwxq3Vg6NNZNjiJdsc1dLUNWG+oQQiingn4//ePD6+PpDy/xqfv7Y3Vc2D343p3kZkxj7fJj+9O5HtYaLUeFWTwje6tP/9ni7m2bRC6Y83Kr0WNYvv0akW2u6ffn0GsBy0dclYo0sVRffn4WSEtNtjjhVGRflmtjC/TFxrpPK1PRJJ/zKeTRVwARTNxlupH9e7gRLW+zhHIv8L1L+FtlDuWlq6raSDMXp/NgETmD4SBU=
EOF
    sudo cp "$config_dir/bell.ogg" /usr/share/sounds/ubuntu/stereo/bell.ogg
    set_state gstreamer
}

function state_gstreamer() {
    if ! sudo apt-get install -y \
        libgstreamer1.0-0 \
        gstreamer1.0-plugins-base \
        gstreamer1.0
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-doc \
        gstreamer1.0-tools \
        # eol
    then
        exit 1
    fi
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
        if ! sudo dpkg -i google-chrome-stable_current_amd64.deb
        then
            exit 1
        fi
        popd
    fi
    set_state install
}

function state_install() {
    if ! sudo apt install -y \
        audacity \
        codeblocks \
        cmake \
        clang \
        default-jdk \
        geany \
        inkscape \
        maven \
        pylint3 \
        wxmaxima \
        xclip \
        # eol
    then
        exit 1
    fi

#    if ! sudo snap install netbeans --classic
#    then
#        exit 1
#    fi

    if ! sudo snap install gimp
    then
        exit 1
    fi
    if ! sudo snap install vlc
    then
        exit 1
    fi
    if ! sudo snap install octave --beta
    then
        exit 1
    fi
    if ! sudo snap install code --classic
    then
        exit 1
    fi
    if ! sudo snap install node --classic --channel=10
    then
        exit 1
    fi
    set_state conda
}

function state_conda() {
#
#    does not work...
#
#    if ! sudo snap install conda --beta
#    then
#        exit 1
#    fi
    if [ ! -d ~/.conda ]
    then
	pushd ~/Downloads
	local version=Anaconda3-2020.02-Linux-x86_64.sh
	local conda=$HOME/anaconda3/bin/conda
	
	if [ ! -f $version ]
	then
	    wget https://repo.anaconda.com/archive/$version
	fi
	mkdir ~/.conda
	bash $version -b
	echo y | $conda update -n root conda
	echo y | $conda update --all
	$conda init bash
	$conda config --set auto_activate_base false
	local pyversion=3.7
	echo y | $conda create --name py python=$pyversion
	bash -i -c "
	    conda activate py
	    echo y | $conda install -c conda-forge jupyterlab
	"
	echo y | $conda create --name cpp python=$pyversion
	bash -i -c "
	    conda activate cpp
	    echo y | conda install -c conda-forge jupyterlab
	    echo y | conda install -c conda-forge xeus-cling
	"
	echo y | $conda create --name r r-recommended r-irkernel jupyterlab
    fi
    set_state docker
}

# skipped
function state_wine() {
    if ! which wine
    then
	pushd ~/Downloads
	if ! sudo dpkg --add-architecture i386
	then
	    exit 1
	fi
	/bin/rm -rf winehq.key
	wget -nc https://dl.winehq.org/wine-builds/winehq.key
	if ! sudo apt-key add winehq.key
	then
	    exit 1
	fi
	if ! sudo apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main'
	then
	    exit 1
	fi

	if ! sudo apt update
	then
	    exit 1
	fi
	if ! sudo apt install -y --install-recommends winehq-stable
	then
	    exit 1
	fi
	popd
    fi
    set_state docker
}

# skipped
function state_lxd() {
    if ! lxc profile device list default | grep -q "eth0"
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
        sudo apt install lxd
        sudo lxd init --preseed <"$preseed"
        sudo adduser $USER lxd
    fi
        
    set_state docker
}

function state_docker() {
    if [ $(apt-key export "Docker Release (CE deb) <docker@docker.com>" | wc -c) = "0" ]
    then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    fi
    
    if ! cat /etc/apt/sources.list /etc/apt/sources.list.d/* | egrep "^deb" | grep -q "download.docker.com"
    then
        sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
        sudo apt update
    fi
    sudo apt install -y docker-ce docker-compose
    set_state veracrypt
}

function state_veracrypt() {
    VERACRYPT_VER=1.24-Update7
    VERACRYPT_VER=1.24-Update7
    VERACRYPT_ver=$(echo $VERACRYPT_VER | sed -e 's/\(.*\)/\L\1/')
    VERACRYPT_DEB=veracrypt-$VERACRYPT_VER-Ubuntu-20.04-amd64.deb
    if ! which veracrypt
    then
        if ! -f ~/Downloads/$VERACRYPT_DEB
        then
            (cd ~/Downloads && wget https://launchpad.net/veracrypt/trunk/$VERAC\
RYPT_ver/+download/$VERACRYPT_DEB)
        fi
        if ! sudo dpkg -i ~/Downloads/$VERACRYPT_DEB
        then
            exit 1
        fi
    fi
    set_state exfat
}

function state_exfat() {
  
    if ! which dumpexfat
    then
	# https://itectec.com/ubuntu/ubuntu-20-04-and-exfat/
	sudo apt install -y exfat-utils
	sudo apt remove -y exfat-fuse
    fi
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
