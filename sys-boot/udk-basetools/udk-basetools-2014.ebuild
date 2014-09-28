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
SRC_URI="${UDK_TARBALL}"

LICENSE="BSD-2"
KEYWORDS="~amd64"
IUSE="udk-toolchain test"

RDEPEND="${PYTHON_DEPS}
	udk-toolchain? ( sys-boot/udk-toolchain-X86:${UDK_SLOT} )"
DEPEND="${RDEPEND}
	app-arch/unzip"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

pkg_setup() {
	use udk-toolchain && ewarn "udk-toolchain builds are untested, expect trouble."
	python-single-r1_pkg_setup
}

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

src_configure() {
	export {C,CXX,CPP,LD}FLAGS
	tc-export AR AS CC CPP CXX LD NM PKG_CONFIG RANLIB
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
	if use udk-toolchain; then
		cat > "${T}"/GentooUDKToolchainNotes.txt <<-EOF
			Since the UDK toolchain is fairly ungentoolike (and since Greg is lazy,
			truth be told), we simply install it to ${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/X86,
			rather than rely on crossdev or any similar technology.
	
			Since Gentoo's gcc-config won't know about it, we place a sourcable bash
			script at "${EPREFIX}/opt/UDK${UDK_SLOT}/tc-env.sh", which contains bash script
			code capable of selecting between these toolchains.
	
			To use it, source the file and then invoke the udk${UDK_SLOT}_tc_select
			function like so:
	
			  $ . "${EPREFIX}/opt/UDK${UDK_SLOT}/tc-env.sh"; udk${UDK_SLOT}_tc_select X86
	
			To undo these modifications, one may similarly invoke the
			udk${UDK_SLOT}_tc_deselect function, also with the argument "X86".
		EOF
		dodoc "${T}"/GentooUDKToolchainNotes.txt
		cat > "${ED}opt/UDK${UDK_SLOT}"/tc-env.sh <<-EOF
			# source me
	
			udk${UDK_SLOT}_tc_forcedir() {
			    local x
			    pushd "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}" >/dev/null
			    x=\$(find . -maxdepth 1 -type d -name '*-*-*' | head -n 1 | sed 's/^..//')
			    popd >/dev/null
			    echo "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/\${x}/bin"
			}
	
			udk${UDK_SLOT}_tc_select() {
			    [[ -d "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}" ]] || {
			        echo "Cannot select toolchain \${1} as \\"${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}\\" is not a valid directory." >&2
			        return 1
			    }
			    udk${UDK_SLOT}_tc_deselect "\${1}"
			    export PATH="${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/bin:\${PATH}"
			    export INFOPATH="${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/info:${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/share/info\${INFOPATH:+:\${INFOPATH}}"
			    export MANPATH="${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/man:${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/share/man\${MANPATH:+:\${MANPATH}}"
			    [[ \${2} == --force ]] && \\
			        export PATH="\$(udk${UDK_SLOT}_tc_forcedir "\${1}"):\${PATH}"
			}
	
			pathstrip() {
			    local what=\${1}
			    local var=\${2:-PATH}
			    local varval=\${!var}
			    declare -a comps
			    local comp
			    while [[ -n \${varval} ]] ; do
			        case "\${varval::1}" in
			            :) if [[ \${comp} ]]; then comps+=("\${comp}"); comp= ; fi;;
			            *) comp+="\${varval::1}";;
			        esac
			        varval=\${varval:1}
			    done
			    [[ \${comp} ]] && comps+=("\${comp}")
			    local rslt
			    local notfound=1
			    local first=1
			    for comp in "\${comps[@]}"; do
			        if [[ \${notfound} && \${comp} == \${what} ]]; then
			            notfound=
			            continue
			        else
			            if [[ \${first} ]]; then
			                first=
			            else
			                rslt+=":"
			            fi
			            rslt+="\${comp}"
			        fi
			    done
			    eval \${var}=\\"\\\${rslt}\\"
			}
	
			udk${UDK_SLOT}_tc_deselect() {
			    [[ -d "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}" ]] || {
			        echo "Cannot deselect toolchain \${1} as \\"${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}\\" is not a valid directory." >&2
			        return 1
			    }
			    pathstrip "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/bin" PATH
			    pathstrip "\$(udk${UDK_SLOT}_tc_forcedir "\${1}")" PATH
			    pathstrip "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/info" INFOPATH
			    pathstrip "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/share/info" INFOPATH
			    pathstrip "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/man" MANPATH
			    pathstrip "${EPREFIX}/opt/UDK${UDK_SLOT}/toolchain/\${1}/share/man" MANPATH
			}
		EOF
	fi
}
