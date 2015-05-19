# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE=sqlite

inherit check-reqs toolchain-funcs flag-o-matic versionator multiprocessing eutils python-single-r1

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

OPENSSL_MYPV="0.9.8y"
OPENSSL_THEIRPV="0.9.8w"

DESCRIPTION="UDK (UEFI Development Kit, aka the TianoCore EDKII) is an SDK for creating UEFI drivers, applications and images."
HOMEPAGE="http://sourceforge.net/apps/mediawiki/tianocore/index.php?title=EDK2"
SRC_URI="${UDK_URI}
	mirror://openssl/source/openssl-${OPENSSL_MYPV}.tar.gz"
LICENSE="BSD-2"
KEYWORDS="~amd64"
IUSE="debug"

RDEPEND="${PYHON_DEPS}
	>=sys-boot/udk-basetools-2014-r1:${UDK_SLOT}
	sys-power/iasl"
DEPEND="${DEPEND}
	app-arch/unzip"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RESTRICT="mirror strip splitdebug"
QA_EXECSTACK='*.obj *.dll *.lib *.debug'
QA_WX_LOAD='*.obj *.dll *.lib *.debug'

pkg_pretend() {
	if [[ ${MERGE_TYPE} != buildonly ]] ; then
		# When the caller already has the package installed in this slot, 
		# assume they don't need any space... potentially flakey, but
		# perhaps a useful kludge, for folks with small "/" partitions
		if ( ! has_version ${CATEGORY}/${PN}:${SLOT} ) ; then
			# Here I abuse private check-reqs API since it doesn't offer an
			# in-built means to check for required space in /opt (which is
			# reasonably likely to be in "/" for those so unfortunate
			# as to have split-/usr systems).
			ebegin "UDK is a hog. Checking space requirements in /opt"
			unset CHECKREQS_FAILED
			check-reqs_disk /opt 1G
			check-reqs_output
			unset CHECKREQS_FAILED
		fi
	fi
	CHECKREQS_DISK_BUILD="2G"
	check-reqs_pkg_pretend
}

src_unpack() {
	mkdir -p "${S}" || die
	cd "${S}" || die
	default
	ebegin "Unpacking goofy nested archives..."
	unzip -q "UDK${UDK_PV}.MyWorkSpace.zip" || { eend 1; die "Failure unzipping "UDK${UDK_PV}.MyWorkSpace.zip"; }
	eend 0
}

src_prepare() {
	einfo Converting dos-format text files to UNIX...
	local f
	find "${S}" -type f \
		\( \
			-name '*.raw' -o -name '*.efi' -o -name '*.uni' -o -name '*.lib' \
			-o -name '*.exe' -o -name '*.com' -o -name '*.com2' \
			-o -name '*.zip' -o -name '*.chm' -o -name '*.tar' \
		\) -prune -o -type f -print | \
			while read f ; do
				edos2unix "${f}"
			done
	einfo "injecting OpenSSL version ${OPENSSL_MYPV} in place of ${OPENSSL_THEIRPV}"
	rm -rf "MyWorkSpace/CryptoPkg/Library/OpensslLib/openssl-${OPENSSL_THEIRPV}" || die
	mv -v "openssl-${OPENSSL_MYPV}" "MyWorkSpace/CryptoPkg/Library/OpensslLib/openssl-${OPENSSL_THEIRPV}" || die
	pushd "MyWorkSpace/CryptoPkg/Library/OpensslLib/openssl-${OPENSSL_THEIRPV}" >/dev/null || die
	epatch ${FILESDIR}/openssl-0.9.8h-ldflags.patch
	epatch ${FILESDIR}/openssl-0.9.8m-binutils.patch
	epatch "../EDKII_openssl-${OPENSSL_THEIRPV}.patch"
	cd .. || die
	chmod +x Install.sh || die
	./Install.sh || die
	popd >/dev/null || die
}

set_conf_option() {
	local conffile="${WORKSPACE}/Conf/${1}.txt"
	local param=${2}
	local value=${3}
	[[ $# -eq 3 ]] || die "set_conf_option usage should be: conf_file param value"
	[[ -f "${conffile}" ]] || die "conf_file ${conffile} not found in $(pwd)"
	sed -e "/^${param}[[:space:]]*=/ s|=.*$|= ${value}|" -i ${conffile} \
		|| die "Couldn't set param ${param} in ${conffile}"
}

setup_build_env() {
	strip-flags
	filter-flags '-g* -O3 -m*'
	export {C,CXX,CPP,LD}FLAGS
	tc-export AR AS CC CPP CXX LD NM PKG_CONFIG RANLIB
	export WORKSPACE="${S}/MyWorkSpace"
	cd "${WORKSPACE}"
	export EDK_TOOLS_PATH="${EPREFIX}/opt/UDK${UDK_SLOT}/BaseTools"
	export BASE_TOOLS_PATH="${EDK_TOOLS_PATH}"
	export PATH="${EDK_TOOLS_PATH}/BinWrappers/PosixLike:${PATH}"
}

src_configure() {
	setup_build_env

	filter-flags '-g*'
	strip-flags

	local SAVEPATH="${PATH}"
	source "${EDK_TOOLS_PATH}"/BuildEnv "${EDK_TOOLS_PATH}" || die
	einfo "Resetting path changes from \"${PATH}\" to \"${SAVEPATH}\"."
	export PATH="${SAVEPATH}"

	local gcc_majorminor=$(gcc-major-version)$(gcc-minor-version)
	case ${gcc_majorminor} in
		44|45|46|47|48|49) :;;
		*) gcc_majorminor=48;;
	esac
	set_conf_option tools_def "DEFINE GCC${gcc_majorminor}_X64_PREFIX" ${CHOST}-
	toolchaintag="GCC${gcc_majorminor}"

	set_conf_option target    TOOL_CHAIN_TAG                      ${toolchaintag}
	set_conf_option tools_def 'DEFINE UNIX_IASL_BIN'              "${EPREFIX}/usr/bin/iasl"
	set_conf_option target    TARGET_ARCH                         X64
	set_conf_option target    TARGET                              RELEASE
	set_conf_option target    MAX_CONCURRENT_THREAD_NUMBER        $(makeopts_jobs)
	set_conf_option target    ACTIVE_PLATFORM                     MdeModulePkg/MdeModulePkg.dsc
}

src_compile() {
	local platform platformpkg subplatform
	for platform in \
		Crypto Duet Fat IntelFrameworkModule IntelFramework \
		MdeModule Mde Network PcAtChipset Performance Security \
		Shell SourceLevelDebug UefiCpu ; \
	do
		platformpkg="${platform}Pkg"
		subplatform="${platformpkg}"
		if [[ ${platform} == Duet ]]; then
			subplatform+="X64"
		else
			einfo "Building ${platformpkg}/${subplatform}..."
			build -a X64 -b RELEASE -t ${toolchaintag} -p ${platformpkg}/${subplatform}.dsc || die
		fi
		if use debug; then
			build -a X64 -b DEBUG -t ${toolchaintag} -p ${platformpkg}/${subplatform}.dsc || die
		fi
	done
}

src_install() {
	insinto "/opt/UDK${UDK_SLOT}"
	doins -r Documents
	cd "${WORKSPACE}" || die
	local d
	while read d; do
		einfo "Installing from ${d}..."
		cd "${WORKSPACE}/${d}" || die
		exeinto "/opt/UDK${UDK_SLOT}/${d}"
		insinto "/opt/UDK${UDK_SLOT}/${d}"
		find . -mindepth 1 -maxdepth 1 -type f \( \
			-name '*.obj' -prune \
			-o -perm /111 -execdir doexe \{\} + \
			-o -execdir doins \{\} + \
		\) || die
	done < <( find . -mindepth 1 -type d | sed 's|^\./||' )
}
