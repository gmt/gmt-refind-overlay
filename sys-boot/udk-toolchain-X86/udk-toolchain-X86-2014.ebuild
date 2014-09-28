# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python2_7 )

inherit eutils versionator flag-o-matic toolchain-funcs python-single-r1

UDK_SLOT="$(get_major_version)"
SLOT="${UDK_SLOT}"

GCC_PV="4.3.0"
BINUTILS_PV="2.20.51.0.5"

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

DESCRIPTION="Cross-compiling X64 toolchain for UDK-${UDK_PV}"
HOMEPAGE="http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=Unix-like_systems#Build_gcc_x64_UEFI_cross_compiler"

GCC_TARBALL="gcc-${GCC_PV}.tar.bz2"
GCC_URI="mirror://gnu/gcc/gcc-${GCC_PV}/${GCC_TARBALL}"

# it's gone from all other mirrors unfortunately... it'd
# be better to be more flexible about the versions; however,
# for now getting the exact ones upstream wants is the path of
# least resistance.
BINUTILS_TARBALL="binutils-${BINUTILS_PV}.tar.bz2"
BINUTILS_URI="https://distfiles.macports.org/binutils/${BINUTILS_TARBALL}"

SRC_URI="${UDK_URI} ${GCC_URI} ${BINUTILS_URI}"
LICENSE="GPL-3 LGPL-3 GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ ) FDL-1.2+"
RESTRICT="strip"

KEYWORDS="~amd64"

RDEPEND=">=dev-libs/mpfr-2.4.2
	>=dev-libs/gmp-4.3.2"
DEPEND="${PYTHON_DEPS}
	${RDEPEND}
	app-arch/unzip"

pkg_setup() { 
	if use amd64; then
		ewarn "You almost certainly don't need to use this package -- "
		ewarn "just disable the udk-toolchain useflag instead. But just"
		ewarn "maybe you have some other reason, who knows.  Using this might"
		ewarn "even work, for all anybody knows :)"
	else
		ewarn "Welcome to an obscure and poorly tested code path.  Good luck!"
	fi
	python-single-r1_pkg_setup
}

src_unpack() {
	unpack "${UDK_TARBALL}"
	unpack "./BaseTools(Unix).tar"
	rm -rf Base*.tar Base*.zip Conf Documents Notes UDK*.txt UDK*.zip edksetup.sh 
	mv BaseTools/gcc "${P}"
	rm -rf BaseTools

	cd "${S}"

	mkdir src || die
	# wasteful but safer/easier than hacking up the scripts for now
	cp "${DISTDIR}/${GCC_TARBALL}" "${DISTDIR}/${BINUTILS_TARBALL}" -t ./src || die
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-dont-download-stuff.patch
	epatch "${FILESDIR}"/${P}-dump-output.patch
	epatch "${FILESDIR}"/${P}-patchsupport.patch
	epatch "${FILESDIR}"/${P}-gentooify.patch
	for m in gcc binutils ; do
		for p in "${FILESDIR}/${PVR}/${m}"-*.patch; do 
			[[ -f "${p}" ]] || continue
			mkdir -p patches/${m} || die
			pshort=${p##*/}
			pshort=${pshort#${m}-}
			einfo "Adding patch ${pshort} to patches/${m} for future application"
			cp "${p}" "patches/${m}/${pshort}" || die
		done
	done
	epatch_user
}

src_configure() {
	strip-flags
	myconf=(
		--verbose
		--arch=x64
		--makeopts="${MAKEOPTS}"
		--prefix="${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/X64"
		--destdir="${S}"/install-image
	)
	export {C,CXX,CPP,LD}FLAGS
	tc-export AR AS CC CPP CXX LD NM PKG_CONFIG RANLIB
}

src_compile() {
	echo yes | { tc-env_build ${PYTHON} mingw-gcc-build.py "${myconf[@]}" || die ; }
}

src_install() {
	dodoc README.txt
	cp -av "${S}"/install-image/* "${ED}" || die "Failed to transplant sysroot into ${ED}"
}
