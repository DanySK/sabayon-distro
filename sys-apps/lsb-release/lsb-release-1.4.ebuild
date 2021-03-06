# Copyright 1999-2013 Sabayon
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="LSB version query program"
HOMEPAGE="http://www.linuxbase.org/"
SRC_URI="mirror://sourceforge/lsb/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86"
IUSE=""

# Perl isn't needed at runtime, it is just used to generate the man page.
DEPEND="dev-lang/perl"
RDEPEND=""

src_unpack() {
	unpack ${A}

	cd "${S}"
	epatch "${FILESDIR}/${PN}-sabayon-version.patch"
}

src_install() {
	emake \
		prefix="${D}/usr" \
		mandir="${D}/usr/share/man" \
		install \
		|| die "emake install failed"

	mkdir -p "${D}/etc"
	cat > "${D}/etc/lsb-release" <<- EOF
		DISTRIB_ID="Sabayon"
	EOF
}
