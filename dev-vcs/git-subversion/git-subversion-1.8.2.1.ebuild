# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

GENTOO_DEPEND_ON_PERL=no

PYTHON_DEPEND="2"
[[ ${PV} == *9999 ]] && SCM="git-2"
EGIT_REPO_URI="git://git.kernel.org/pub/scm/git/git.git"

inherit toolchain-funcs eutils multilib python ${SCM}

MY_PV="${PV/_rc/.rc}"
MY_PN="${PN/-subversion}"
MY_P="${MY_PN}-${MY_PV}"

DOC_VER=${MY_PV}

DESCRIPTION="Subversion module for GIT, the stupid content tracker"
HOMEPAGE="http://www.git-scm.com/"
if [[ ${PV} != *9999 ]]; then
	SRC_URI_SUFFIX="gz"
	SRC_URI_GOOG="http://git-core.googlecode.com/files"
	SRC_URI_KORG="mirror://kernel/software/scm/git"
	SRC_URI="${SRC_URI_GOOG}/${MY_P}.tar.${SRC_URI_SUFFIX}
			${SRC_URI_KORG}/${MY_P}.tar.${SRC_URI_SUFFIX}
			${SRC_URI_GOOG}/${MY_PN}-manpages-${DOC_VER}.tar.${SRC_URI_SUFFIX}
			${SRC_URI_KORG}/${MY_PN}-manpages-${DOC_VER}.tar.${SRC_URI_SUFFIX}
			doc? (
			${SRC_URI_KORG}/${MY_PN}-htmldocs-${DOC_VER}.tar.${SRC_URI_SUFFIX}
			${SRC_URI_GOOG}/${MY_PN}-htmldocs-${DOC_VER}.tar.${SRC_URI_SUFFIX}
			)"
	KEYWORDS="~amd64 ~x86"
else
	SRC_URI=""
	KEYWORDS=""
fi

SRC_URI+=" mirror://sabayon/dev-vcs/git/git-1.8.2-Gentoo-patches.tgz"

LICENSE="GPL-2"
SLOT="0"
IUSE="doc +threads"

RDEPEND="~dev-vcs/git-${PV}[-subversion,perl]
	dev-perl/Error
	dev-perl/Net-SMTP-SSL
	dev-perl/Authen-SASL
	dev-vcs/subversion[-dso,perl] dev-perl/libwww-perl dev-perl/TermReadKey"
DEPEND="app-arch/cpio
	doc? (
		app-text/asciidoc
		app-text/docbook2X
		sys-apps/texinfo
		app-text/xmlto
	)"

# Live ebuild builds man pages and HTML docs, additionally
if [[ ${PV} == *9999 ]]; then
	DEPEND="${DEPEND}
		app-text/asciidoc"
fi

S="${WORKDIR}/${MY_P}"

# This is needed because for some obscure reasons future calls to make don't
# pick up these exports if we export them in src_unpack()
exportmakeopts() {
	local myopts

	# broken assumptions, because of broken build system ...
	myopts="${myopts} NO_FINK=YesPlease NO_DARWIN_PORTS=YesPlease"
	myopts="${myopts} INSTALL=install TAR=tar"
	myopts="${myopts} SHELL_PATH=${EPREFIX}/bin/sh"
	myopts="${myopts} SANE_TOOL_PATH="
	myopts="${myopts} OLD_ICONV="
	myopts="${myopts} NO_EXTERNAL_GREP="

	# split ebuild: avoid collisions with dev-vcs/git's .mo files
	myopts="${myopts} NO_GETTEXT=YesPlease"

	# For svn-fe
	#extlibs="-lz -lssl ${S}/xdiff/lib.a $(usex threads -lpthread '')"
	extlibs="-lz -lssl -lcrypto ${S}/xdiff/lib.a $(usex threads -lpthread '')"

	# can't define this to null, since the entire makefile depends on it
	sed -i -e '/\/usr\/local/s/BASIC_/#BASIC_/' Makefile

	myopts="${myopts} INSTALLDIRS=vendor"
	myopts="${myopts} NO_SVN_TESTS=YesPlease"
	myopts="${myopts} NO_CVS=YesPlease"

	has_version '>=app-text/asciidoc-8.0' \
		&& myopts="${myopts} ASCIIDOC8=YesPlease"
	myopts="${myopts} ASCIIDOC_NO_ROFF=YesPlease"

	# Bug 290465:
	# builtin-fetch-pack.c:816: error: 'struct stat' has no member named 'st_mtim'
	[[ "${CHOST}" == *-uclibc* ]] && \
		myopts="${myopts} NO_NSEC=YesPlease"

	export MY_MAKEOPTS="${myopts}"
	export EXTLIBS="${extlibs}"
}

src_unpack() {
	if [[ ${PV} != *9999 ]]; then
		unpack ${MY_P}.tar.${SRC_URI_SUFFIX}
		cd "${S}"
		unpack ${MY_PN}-manpages-${DOC_VER}.tar.${SRC_URI_SUFFIX}
		use doc && \
			cd "${S}"/Documentation && \
			unpack ${MY_PN}-htmldocs-${DOC_VER}.tar.${SRC_URI_SUFFIX}
		cd "${S}"
	else
		git-2_src_unpack
	fi

	cd "${WORKDIR}" && unpack git-1.8.2-Gentoo-patches.tgz
}

src_prepare() {
	# bug #418431 - stated for upstream 1.7.13. Developed by Michael Schwern,
	# funded as a bounty by the Gentoo Foundation. Merged upstream in 1.8.0.
	#epatch "${DISTDIR}"/git-1.7.12-git-svn-backport.patch.bz2

	# bug #350330 - automagic CVS when we don't want it is bad.
	epatch "${WORKDIR}"/1.8.2-patches/git-1.8.2-optional-cvs.patch

	# bug #464210 - texinfo anchors
	epatch "${WORKDIR}"/1.8.2-patches/git-1.8.2-texinfo.patch

	sed -i \
		-e 's:^\(CFLAGS =\).*$:\1 $(OPTCFLAGS) -Wall:' \
		-e 's:^\(LDFLAGS =\).*$:\1 $(OPTLDFLAGS):' \
		-e 's:^\(CC = \).*$:\1$(OPTCC):' \
		-e 's:^\(AR = \).*$:\1$(OPTAR):' \
		-e "s:\(PYTHON_PATH = \)\(.*\)$:\1${EPREFIX}\2:" \
		-e "s:\(PERL_PATH = \)\(.*\)$:\1${EPREFIX}\2:" \
		Makefile contrib/svn-fe/Makefile || die "sed failed"

	# Fix docbook2texi command
	sed -i 's/DOCBOOK2X_TEXI=docbook2x-texi/DOCBOOK2X_TEXI=docbook2texi.pl/' \
		Documentation/Makefile || die "sed failed"

	# Never install the private copy of Error.pm (bug #296310)
	sed -i \
		-e '/private-Error.pm/s,^,#,' \
		perl/Makefile.PL
}

git_emake() {
	# bug #326625: PERL_PATH, PERL_MM_OPT
	# bug #320647: PYTHON_PATH
	PYTHON_PATH="$(PYTHON -a)"
	emake ${MY_MAKEOPTS} \
		DESTDIR="${D}" \
		OPTCFLAGS="${CFLAGS}" \
		OPTLDFLAGS="${LDFLAGS}" \
		OPTCC="$(tc-getCC)" \
		OPTAR="$(tc-getAR)" \
		prefix="${EPREFIX}"/usr \
		htmldir="${EPREFIX}"/usr/share/doc/${PF}/html \
		sysconfdir="${EPREFIX}"/etc \
		PYTHON_PATH="${PYTHON_PATH}" \
		PERL_MM_OPT="" \
		GIT_TEST_OPTS="--no-color" \
		V=1 \
		"$@"
	# This is the fix for bug #326625, but it also causes breakage, see bug
	# #352693.
	# PERL_PATH="${EPREFIX}/usr/bin/env perl" \
}

src_configure() {
	exportmakeopts
}

src_compile() {
	#if use perl ; then
	git_emake perl/PM.stamp || die "emake perl/PM.stamp failed"
	git_emake perl/perl.mak || die "emake perl/perl.mak failed"
	#fi

	git_emake || die "emake failed"

	cd "${S}"/Documentation
	if [[ ${PV} == *9999 ]] ; then
		git_emake man \
			|| die "emake man failed"
		if use doc ; then
			git_emake info html \
				|| die "emake info html failed"
		fi
	else
		if use doc ; then
			git_emake info \
				|| die "emake info html failed"
		fi
	fi

	cd "${S}"/contrib/svn-fe
	git_emake EXTLIBS="${EXTLIBS}" || die "emake svn-fe failed"
	if use doc ; then
		git_emake svn-fe.{1,html} || die "emake svn-fe.1 svn-fe.html failed"
	fi
}

src_install() {
	git_emake install || die "make install failed"

	rm -r "${ED}"usr/share/gitweb || die
	rm -r "${ED}"usr/bin || die
	rm -r "${ED}"usr/share/git-core/templates || die
	rm -r "${ED}"usr/share/git-gui || die
	rm -r "${ED}"usr/share/gitk || die

	# avoid conflict with dev-vcs/git
	# it looks weird but this binary is installed by git ebuild
	# so removing in git-subversion
	rm "${ED}"usr/libexec/git-core/git-remote-testsvn

	for myfile in "${ED}"usr/libexec/git-core/* "${ED}"usr/$(get_libdir)/* "${ED}"usr/share/man/*/*; do
		case "$myfile" in
		*svn*)
			true ;;
		*)
			rm -r "${myfile}" || die ;;
		esac
	done

	local libdir="${ED}"usr/$(get_libdir)
	if [ -d "${libdir}" ]; then
		# must be empty
		rmdir "${libdir}" || die
	fi

	doman man*/*svn* || die
	if use doc; then
		docinto /
		dodoc Documentation/*svn*.txt
		dohtml -p / Documentation/*svn*.html
	fi

	cd "${S}"/contrib/svn-fe
	dobin svn-fe
	dodoc svn-fe.txt
	use doc && doman svn-fe.1 && dohtml svn-fe.html
	cd "${S}"

	# kill empty dirs from ${ED}
	find "${ED}" -type d -empty -delete || die
}
