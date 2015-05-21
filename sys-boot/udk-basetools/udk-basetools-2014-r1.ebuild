# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE=sqlite

inherit eutils versionator python-single-r1

UDK_SLOT="$(get_major_version)"
SLOT="${UDK_SLOT}"

UDK_REL=$(get_version_component_range '2-4')
while [[ $(get_version_component_count "${UDK_REL}") -lt 3 ]] ; do
	UDK_REL="${UDK_REL}.0"
done
UDK_REL=$(version_format_string '.SR${1}.UP${2}.P${3}' "${UDK_REL}")
UDK_REL=${UDK_REL/.P0/}
UDK_REL=${UDK_REL/.UP0/}
UDK_REL=${UDK_REL/.SR0/}
UDK_PV="${UDK_SLOT}${UDK_REL}"

UDK_TARBALL="UDK${UDK_PV}.Complete.MyWorkSpace.zip"
UDK_URI="mirror://sourceforge/edk2/UDK${UDK_SLOT}_Releases/UDK${UDK_PV}/${UDK_TARBALL}"

DESCRIPTION="Set of tools for processing UDK II content."
HOMEPAGE="http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=EDK2"
SRC_URI="${UDK_URI}"

LICENSE="BSD-2"
KEYWORDS="~amd64"
IUSE="test"

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	app-arch/unzip"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RESTRICT="primaryuri"

src_unpack() {
	mkdir -p "${S}" || die
	cd "${S}" || die
	default
	unpack ./BaseTools\(Unix\).tar
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2014-gcc49-support.patch
	# do not run tests as part of "all" target
	sed -e 's|^\(SUBDIRS := .* \)Tests|\1|' \
		-i BaseTools/GNUmakefile || die
	local f
	einfo Converting files to from DOS to UNIX style line-endings
	find BaseTools/{Conf,GNUmakefile,{ReadMe,License,Contributions}.txt,Source,Scripts,BuildEnv} -type f | while read f; do
		edos2unix "${f}"
	done
}


src_compile() {
	ARCH= emake -j1 -C BaseTools
}

src_test() {
	ARCH= emake -j1 -C BaseTools test
}

src_install() {
	exeinto "/opt/UDK${UDK_SLOT}/BaseTools/Source/C/bin"
	doexe BaseTools/Source/C/bin/*
	exeinto "/opt/UDK${UDK_SLOT}/BaseTools/BinWrappers/PosixLike"
	doexe BaseTools/BinWrappers/PosixLike/*
	insinto "/opt/UDK${UDK_SLOT}/BaseTools/Source/C/lib"
	doins BaseTools/Source/C/libs/*
	insinto "/opt/UDK${UDK_SLOT}/BaseTools/Source/C/Include"
	doins -r BaseTools/Source/C/Include/*
	insinto "/opt/UDK${UDK_SLOT}/BaseTools/Conf"
	doins -r BaseTools/Conf/*
	insinto "/opt/UDK${UDK_SLOT}/BaseTools/Scripts"
	doins BaseTools/Scripts/gcc4.4-ld-script
	doins BaseTools/Scripts/gcc4.9-ld-script
	insinto "/opt/UDK${UDK_SLOT}/BaseTools/Source/Python"
	doins -r BaseTools/Source/Python/*
	insinto "/opt/UDK${UDK_SLOT}/BaseTools"
	doins BaseTools/BuildEnv
	dodoc BaseTools/{ReadMe,License,Contributions}.txt
	dodoc BaseTools/UserManuals/*
}
