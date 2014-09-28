# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils flag-o-matic

DESCRIPTION="The rEFInd U/EFI Boot Manager"
HOMEPAGE="http://www.rodsbooks.com/refind"
SRC_URI="mirror://sourceforge/refind/${PV}/${PN}-src-${PV}.zip"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+fsdrivers udk"

UDK_SLOT=2010

DEPEND="udk? ( sys-boot/udk:${UDK_SLOT}[-udk-toolchain] ) !udk? ( sys-boot/gnu-efi )"
RDEPEND="${DEPEND}"

DOCS=( {COPYING,CREDITS,LICENSE,README,NEWS}.txt )

RESTRICT="strip splitdebug"

pkg_setup() {
	if use udk; then
		ewarn "UDK builds may have trouble booting Arch linux."
	else
		ewarn "gnu-efi (non-UDK) builds cannot boot legacy-BIOS targets."
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.7.9-UDK-location-${UDK_SLOT}.patch
}

src_configure() {
	strip-flags
	filter-flags '-g* -O3 -m*'
    export {C,CXX,CPP,LD}FLAGS
    tc-export AR AS CC CPP CXX LD NM PKG_CONFIG RANLIB
	if has_version "sys-boot/udk-basetools:${UDK_SLOT}[udk-toolchain]"; then
        source ${EPREFIX}/opt/UDK${UDK_SLOT}/tc-env.sh || die
		udk${UDK_SLOT}_tc_select X64 --force
	fi
    export EDK_TOOLS_PATH="${EPREFIX}/opt/UDK${UDK_SLOT}/BaseTools"
    export PATH="${EDK_TOOLS_PATH}/BinWrappers/PosixLike:${PATH}"
	unset ARCH
	export ARCH
}

src_compile() {
	if use udk; then
		emake -j1
		use fsdrivers && emake -j1 fs
	else
		# upstream bug: parallel make is all kinds of broken: both targets
		# must be provided to nonparallel make at once or else no dice.
		if use fsdrivers; then
			emake -j1 gnuefi fs_gnuefi
		else
			# ... somehow parallel-make seems OK in this case.
			emake gnuefi
		fi
	fi
}

src_install() {
	dodoc "${DOCS[@]}"
	dodoc -r docs/Styles
	dodoc -r docs/refind/*
	pushd "${ED}"usr/share/doc/${PF} 2>/dev/null || die
	for f in *.html ; do
		[[ -f "${f}" ]] || die
		sed -e 's|\.\./Styles|Styles|g' -i "${f}" || die
	done
	popd 2>/dev/null || die
	insinto ${EROOT}usr/share/${PN}
	exeinto ${EROOT}usr/share/${PN}
	doins refind.conf-sample
	doins refind/*.efi
	doexe *.sh
	sed -e '/^RefindDir=/ s|/refind||' -i "${ED}"usr/share/${PN}/install.sh || die
	doins -r icons keys fonts banners 
	chmod a+x ${ED}usr/share/${PN}/fonts/mkfont.sh || die
	insinto ${EROOT}usr/share/${PN}/gptsync
	doins gptsync/*.efi
	insinto ${EROOT}usr/share/${PN}/images
	doins images/*.png
	insinto ${EROOT}usr/share/${PN}/filesystems
	use fsdrivers && doins filesystems/*.efi
}

pkg_postinst() {
	elog "A sample configuration file is placed into ${EROOT}usr/share/${PF}/refind.conf-sample."
	elog
	elog "This ebuild does not install files to the ESP"
	elog "You need to manually copy or use the provided install.sh script"
	elog	
	elog "See ${EROOT}usr/share/doc/${PF}/installing.html file for details."
}
