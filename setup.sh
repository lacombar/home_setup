#!/bin/sh

set -eu

die()
{
	echo "$@"
	exit 1
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
}

sudo -s echo -n

setup_repositories

#
#
echo " * Installing essentials utilities ..."
sudo dnf install -y \
	aterm \
	dnf-automatic \
	redshift \
	screen \
	wget \
	zsh

echo " * Installing Pertino client"
sudo dnf install pertino-client

echo " * Installing development tools ..."
sudo dnf install -y \
	clang \
	lldb \
	gdb \
	gcc \

echo " * Installing web browsers ..."
sudo dnf install -y \
	firefox \
	google-chrome-beta \
	google-chrome-stable

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

echo " * Configuring dnf-automatic"
sudo systemctl start dnf-automatic.timer
sudo systemctl enable dnf-automatic.timer
