#!/bin/bash
#
# Copyright (c) 2019 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

cidir=$(dirname "$0")
source "/etc/os-release" || "source /usr/lib/os-release"
source "${cidir}/lib.sh"

echo "Get repo for perl-IPC-Run"
sudo -E yum-config-manager --enable rhui-rhel-7-server-rhui-optional-rpms

echo "Add epel repository"
epel_url="https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
sudo -E yum install -y "$epel_url"

echo "Update repositories"
sudo -E yum -y update

echo "Install chronic"
sudo -E yum install -y moreutils

declare -A minimal_packages=( \
	[spell-check]="hunspell hunspell-en-GB hunspell-en-US pandoc" \
	[xml_validator]="libxml2" \
	[yamllint]="yamllint"
)

declare -A packages=(
	[bison_binary]="bison" \
	[build_tools]="pkgconfig python zlib-devel" \
	[cri-containerd_dependencies]="btrfs-progs-devel libseccomp-devel" \
	[crio_dependencies]="btrfs-progs-devel device-mapper-libs glibc-devel glibc-static glib2-devel gpgme-devel libassuan-devel libgpg-error-devel libseccomp-devel libselinux-devel pkgconfig util-linux" \
	[crudini]="crudini" \
	[gnu_parallel_dependencies]="bzip2 make perl" \
	[haveged]="haveged" \
	[kata_containers_dependencies]="autconf automake bc bzip2 coreutils device-mapper-devel device-mapper-persistent-data gettext-devel libtool libtool-ltdl-devel lvm2 m4 patch pixman-devel" \
	[kernel_dependencies]="elfutils-libelf-devel flex" \
	[libsystemd]="systemd-devel" \
	[libudev-dev]="libgudev1-devel" \
	[metrics_dependencies]="jq" \
	[os_tree]="ostree-devel" \
	[procenv]="procenv" \
	[qemu_dependencies]="flex libattr-devel libcap-devel libcap-ng-devel libfdt-devel librbd1-devel libpmem-devel" \
	[redis]="redis" \
)

main()
{
	local setup_type="$1"
	[ -z "$setup_type" ] && die "need setup type"

	local pkgs_to_install
	local pkgs

	for pkgs in "${minimal_packages[@]}"; do
		pkgs_to_install+=" $pkgs"
	done

	if [ "$setup_type" = "default" ]; then
		for pkgs in "${packages[@]}"; do
			info "The following package will be installed: $pkgs"
			pkgs_to_install+=" $pkgs"
		done
	fi

	chronic sudo -E yum -y install $pkgs_to_install

	[ "$setup_type" = "minimal" ] && exit 0

	echo "Install GNU parallel"
	# GNU parallel not available in Centos repos, so build it instead.
	build_install_parallel

	if [ "$KATA_KSM_THROTTLER" == "yes" ]; then
		echo "Install ${KATA_KSM_THROTTLER_JOB}"
		sudo -E yum install ${KATA_KSM_THROTTLER_JOB}
	fi
}

main "$@"
