# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-plugins/alsa-plugins/alsa-plugins-1.0.24.ebuild,v 1.2 2011/04/10 20:21:10 scarabeus Exp $

EAPI=2

MY_P="${P/_/}"

inherit autotools eutils multilib flag-o-matic

DESCRIPTION="ALSA extra plugins"
HOMEPAGE="http://www.alsa-project.org/"
SRC_URI="mirror://alsaproject/plugins/${MY_P}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="debug ffmpeg jack libsamplerate pulseaudio speex"

RDEPEND=">=media-libs/alsa-lib-${PV}[alsa_pcm_plugins_ioplug]
	ffmpeg? ( media-video/ffmpeg
		media-libs/alsa-lib[alsa_pcm_plugins_rate,alsa_pcm_plugins_plug] )
	jack? ( >=media-sound/jack-audio-connection-kit-0.98 )
	libsamplerate? (
		media-libs/libsamplerate
		media-libs/alsa-lib[alsa_pcm_plugins_rate,alsa_pcm_plugins_plug] )
	pulseaudio? ( media-sound/pulseaudio )
	speex? ( media-libs/speex
		media-libs/alsa-lib[alsa_pcm_plugins_rate,alsa_pcm_plugins_plug] )
	!media-plugins/alsa-jack"

DEPEND="${RDEPEND}
	dev-util/pkgconfig"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# For some reasons the polyp/pulse plugin does fail with alsaplayer with a
	# failed assert. As the code works just fine with asserts disabled, for now
	# disable them waiting for a better solution.
	sed -i -e '/AM_CFLAGS/s:-Wall:-DNDEBUG -Wall:' \
		"${S}/pulse/Makefile.am"

	# Bug #256119
	epatch "${FILESDIR}"/${PN}-1.0.19-missing-avutil.patch

	# Bug #278352
	epatch "${FILESDIR}"/${P}-automagic.patch

	eautoreconf
}

src_configure() {
	use debug || append-flags -DNDEBUG

	local myspeex

	if use speex; then
		myspeex=lib
	else
		myspeex=no
	fi

	econf \
		--disable-dependency-tracking \
		$(use_enable ffmpeg avcodec) \
		$(use_enable jack) \
		$(use_enable libsamplerate samplerate) \
		$(use_enable pulseaudio) \
		--with-speex=${myspeex}
}

src_install() {
	emake DESTDIR="${D}" install

	cd "${S}/doc"
	dodoc upmix.txt vdownmix.txt README-pcm-oss
	use jack && dodoc README-jack
	use libsamplerate && dodoc samplerate.txt
	use ffmpeg && dodoc lavcrate.txt a52.txt

	if use pulseaudio; then
		dodoc README-pulse
		# install ALSA configuration files
		# making PA to be used by alsa clients
		insinto /usr/share/alsa
		doins "${FILESDIR}"/pulse*.conf
		# setup proper LDPATH to make possible to load
		# "libasound_module_conf_pulse.so"
		# even for multilib systems
		local ldpath=""
		for libdir in $(get_all_libdirs); do
			ldpath="${ldpath}:/usr/${libdir}/alsa-lib"
		done
		ldpath="${ldpath:1}"
		echo "LDPATH=\"${ldpath}\"" > "${S}/40-alsa-plugin-pulse"
		doenvd "${S}/40-alsa-plugin-pulse"
	fi

}
