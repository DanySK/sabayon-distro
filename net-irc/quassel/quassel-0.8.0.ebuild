# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

EGIT_REPO_URI="git://git.quassel-irc.org/quassel.git"
EGIT_BRANCH="master"
[[ "${PV}" == "9999" ]] && GIT_ECLASS="git-2"

QT_MINIMAL="4.6.0"
KDE_MINIMAL="4.4"

inherit cmake-utils eutils ${GIT_ECLASS}

DESCRIPTION="Qt4/KDE4 IRC client - monolithic client only (no remote daemon)."
HOMEPAGE="http://quassel-irc.org/"
[[ "${PV}" == "9999" ]] || SRC_URI="http://quassel-irc.org/pub/${P/_/-}.tar.bz2"

LICENSE="GPL-3"
KEYWORDS="~amd64 ~x86"
SLOT="0"
# monolithic USE flag is not used, but let's have it here to be compatible
# with Portage ebuild
IUSE="ayatana crypt dbus debug -kde monolithic -phonon postgres +server +ssl webkit X"

SERVER_RDEPEND="
	crypt? (
		app-crypt/qca:2
		app-crypt/qca-ossl
	)
	!postgres? ( >=dev-qt/qtsql-${QT_MINIMAL}:4[sqlite] dev-db/sqlite[-secure-delete] )
	postgres? ( >=dev-qt/qtsql-${QT_MINIMAL}:4[postgres] )
	>=dev-qt/qtscript-${QT_MINIMAL}:4
"

GUI_RDEPEND="
	>=dev-qt/qtgui-${QT_MINIMAL}:4
	ayatana? ( dev-libs/libindicate-qt )
	dbus? (
		>=dev-qt/qtdbus-${QT_MINIMAL}:4
		dev-libs/libdbusmenu-qt
	)
	kde? (
		>=kde-base/kdelibs-${KDE_MINIMAL}
		ayatana? ( kde-misc/plasma-widget-message-indicator )
	)
	phonon? ( || ( media-libs/phonon >=dev-qt/qtphonon-${QT_MINIMAL} ) )
	webkit? ( >=dev-qt/qtwebkit-${QT_MINIMAL}:4 )
"

RDEPEND="
	~net-irc/quassel-common-${PV}
	>=dev-qt/qtcore-${QT_MINIMAL}:4[ssl?]
	${SERVER_RDEPEND}
	${GUI_RDEPEND}
	"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${P/_/-}"

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_with ayatana LIBINDICATE)
		"-DWANT_CORE=OFF"
		"-DWANT_QTCLIENT=OFF"
		"-DWANT_MONO=ON"
		$(cmake-utils_use_with webkit)
		$(cmake-utils_use_with phonon)
		$(cmake-utils_use_with kde)
		$(cmake-utils_use_with dbus)
		$(cmake-utils_use_with ssl OPENSSL)
		"-DWITH_OXYGEN=OFF"
		$(cmake-utils_use_with crypt)
		"-DEMBED_DATA=OFF"
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	rm -rf "${ED}"usr/share/apps
	rm -rf "${ED}"usr/share/pixmaps
	rm -rf "${ED}"usr/share/icons
	rm -rf "${ED}"usr/share/applications

	insinto /usr/share/applications
	doins data/quassel.desktop
}

pkg_postinst() {
	if use ssl ; then
		elog "Information on how to enable SSL support for client/core connections"
		elog "is available at http://bugs.quassel-irc.org/wiki/quassel-irc."
	fi
}
