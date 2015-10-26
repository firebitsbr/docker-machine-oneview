#!/bin/bash
set -e

# usage: ./generate.sh [versions]
#    ie: ./generate.sh
#        to update all Dockerfiles in this directory
#    or: ./generate.sh
#        to only update fedora-20/Dockerfile
#    or: ./generate.sh fedora-newversion
#        to create a new folder and a Dockerfile within it

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
	distro="${version%-*}"
	suite="${version##*-}"
	from="${distro}:${suite}"

	mkdir -p "$version"
	echo "$version -> FROM $from"
	cat > "$version/Dockerfile" <<-EOF
		#
		# THIS FILE IS AUTOGENERATED; SEE "contrib/builder/rpm/generate.sh"!
		#

		FROM $from
	EOF

	echo >> "$version/Dockerfile"

	case "$from" in
		centos:*)
			# get "Development Tools" packages dependencies
			echo 'RUN yum groupinstall -y "Development Tools"' >> "$version/Dockerfile"

			if [[ "$version" == "centos-7" ]]; then
				echo 'RUN yum -y swap -- remove systemd-container systemd-container-libs -- install systemd systemd-libs' >> "$version/Dockerfile"
			fi
			;;
		oraclelinux:*)
			# get "Development Tools" packages and dependencies
			echo 'RUN yum groupinstall -y "Development Tools"' >> "$version/Dockerfile"
			;;
		opensuse:*)
			# get rpm-build and curl packages and dependencies
			echo 'RUN zypper --non-interactive install ca-certificates* curl gzip rpm-build' >> "$version/Dockerfile"
			;;
		*)
			echo 'RUN yum install -y @development-tools fedora-packager' >> "$version/Dockerfile"
			;;
	esac

	# this list is sorted alphabetically; please keep it that way
	packages=(
		btrfs-progs-devel # for "btrfs/ioctl.h" (and "version.h" if possible)
		device-mapper-devel # for "libdevmapper.h"
		glibc-static
		libselinux-devel # for "libselinux.so"
		selinux-policy
		selinux-policy-devel
		sqlite-devel # for "sqlite3.h"
		tar # older versions of dev-tools do not have tar
	)

	case "$from" in
		oraclelinux:7)
			# Enable the optional repository
			packages=( --enablerepo=ol7_optional_latest "${packages[*]}" )
			;;
	esac

	case "$from" in
		opensuse:*)
			packages=( "${packages[@]/btrfs-progs-devel/libbtrfs-devel}" )
			# use zypper
			echo "RUN zypper --non-interactive install ${packages[*]}" >> "$version/Dockerfile"
			;;
		*)
			echo "RUN yum install -y ${packages[*]}" >> "$version/Dockerfile"
			;;
	esac

	echo >> "$version/Dockerfile"

	awk '$1 == "ENV" && $2 == "GO_VERSION" { print; exit }' ../../../Dockerfile >> "$version/Dockerfile"
	echo 'RUN curl -fSL "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" | tar xzC /usr/local' >> "$version/Dockerfile"
	echo 'ENV PATH $PATH:/usr/local/go/bin' >> "$version/Dockerfile"

	echo >> "$version/Dockerfile"

	echo 'ENV AUTO_GOPATH 1' >> "$version/Dockerfile"

	echo 'ENV DOCKER_BUILDTAGS selinux' >> "$version/Dockerfile"
done
