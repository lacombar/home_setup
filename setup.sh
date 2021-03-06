#!/bin/sh

THIS_SCRIPT_DIR="${PWD}/$(dirname "$0")"

. "${THIS_SCRIPT_DIR}/bin/_common.sh"

setup_bin()
{
	local _home_bin="${HOME}/bin"

	[ -d "${_home_bin}" ] &&
		[ ! -h "${_home_bin}" ] &&
		die "\`${_home_bin}' already exist, please remove manually."

	ln -sf "${THIS_SCRIPT_DIR}/bin" "${_home_bin}"
}


setup_rc()
{
	local _rc_dir="${THIS_SCRIPT_DIR}/rc"
	local _rc

	for _rc in "${_rc_dir}/"*; do
		local _filename="$(basename "${_rc}")"
		local _home_rc="${HOME}/.${_filename}"

		[ -e "${_home_rc}" ] &&
			[ ! -h "${_home_rc}" ] &&
			{
				warn "\`${_home_rc}' already exist, please remove manually.'";
				continue;
			}

		ln -sf "${_rc}" "${_home_rc}"
	done
}

setup_repositories()
{
	local _repo

	. "$(dirname "$0")"/yum-repositories.conf

	for _repo in ${ALL_REPOS}; do
		local _description
		local _filename
		local _repo

		eval "_description=\${${_repo}_REPO_DESCRIPTION}"
		eval "_filename=\${${_repo}_REPO_FILENAME}"
		eval "_content=\${${_repo}_REPO}"

		[ -n "${_filename}" ] || \
			die "${_repo}: filename missing"

		[ "$(dirname "${_filename}")" = "." ] || \
			die "${_repo}: bad filename"

		[ -n "${_repo}" ] || \
			die "${_repo}: empty repository"

		sudo sh -c "cat > /etc/yum.repos.d/${_filename}" <<EOF
${_content}
EOF
	done

	sudo dnf install http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	                 http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

setup_packages()
{
	echo " * Installing essentials utilities ..."
	sudo dnf install -y \
		aterm \
		avahi-tools \
		dnf-automatic \
		dnf-plugin-system-upgrade \
		docker \
		global \
		hexedit \
		redshift \
		rsync \
		screen \
		strace \
		system-config-firewall-tui \
		tmux \
		tigervnc \
		tigervnc-server \
		vim \
		w3m \
		wget \
		zsh

	echo " * Installing packages groups ..."
	sudo dnf group install -y \
		"Administration Tools" \
		"Authoring and Publishing" \
		"C Development Tools and Libraries" \
		"Design Suite" \
		"Development Tools" \
		"Engineering and Scientific" \
		"Fedora Eclipse" \
		"Infrastructure Server" \
		LibreOffice \
		"Network Servers" \
		"Office/Productivity" \
		"Security Lab" \
		"System Tools" \
		"Web Server"

	echo " * Installing web browsers ..."
	sudo dnf install -y \
		firefox \
		google-chrome-beta \
		google-chrome-stable

	echo " * Installing Pertino client"
	sudo dnf install -y \
		pertino-client

	echo " * Installing development tools ..."
	sudo dnf install -y \
		awscli \
		bison \
		ccache \
		clang \
		cmake \
		cppcheck \
		cppcheck-gui \
		distcc \
		flex \
		gcc \
		gdb \
		golang \
		libtool \
		lldb \
		lua \
		tig

	echo " * Installing virtualization tools"
	sudo dnf install -y \
		qemu \
		virt-manager

	echo " * Installing misc development libraries"
	sudo dnf install -y \
		docker-devel \
		hiredis-devel \
		libev-devel \
		libevent-devel \
		libidn-devel \
		libpcap-devel \
		libuuid-devel \
		openssl-devel \
		python-devel \
		python-pip \
		uuid-devel

	echo " * Configuring dnf-automatic"
	sudo systemctl start dnf-automatic.timer
	sudo systemctl enable dnf-automatic.timer

	echo " * Removing useless crap"
	sudo dnf remove -y \
		openssh-askpass
}

setup_ssh()
{
	local _dot_ssh="${HOME}/.ssh"

	local _rsa_bits=3072
	local _dsa_bits=1024
	local _ecdsa_bits=384
	local _ed25519_bits=384

	echo " * Generating ssh keys"
	for _type in rsa dsa ecdsa ed25519; do
		local _key_file="${_dot_ssh}/id_${_type}"

		[ ! -e "${_key_file}" ] &&
			eval "ssh-keygen -q -N \"\" -t ${_type} -b \${_${_type}_bits} -f \"${_key_file}\""
	done

	local _authorized_key_file="${_dot_ssh}/authorized_key"
	touch "${_authorized_key_file}"
	chmod 600 "${_authorized_key_file}"
}

setup_xfce4()
{
	:
}

_actions=""
_all_actions="bin rc repositories packages ssh xfce4"

help()
{
	warn "$@"

	die
}

# Warm up sudo(8)
sudo -s echo -n

[ $# = 1 ] || \
	help "$0: wrong argument count"

case "$1" in
	"all")
		_actions="${_all_actions}"
		;;
	"bin")
		_actions="bin"
		;;
	"rc")
		_actions="rc"
		;;
	"repositories")
		_actions="repositories"
		;;
	"packages")
		_actions="packages"
		;;
	"ssh")
		_actions="ssh"
		;;
	"xfce4")
		_actions="xfce4"
		;;
	*)
		help "$1: unknown action"
		;;
esac

for _action in ${_actions}; do
	eval "setup_${_action}"
done
