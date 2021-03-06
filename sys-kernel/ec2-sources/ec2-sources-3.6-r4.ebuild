# Copyright 2004-2010 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

EAPI=5

K_SABKERNEL_SELF_TARBALL_NAME="sabayon"
K_SABKERNEL_NAME="ec2"
K_ONLY_SOURCES="1"
K_SABKERNEL_FORCE_SUBLEVEL="0"
inherit sabayon-kernel
KEYWORDS="~amd64 ~x86"
DESCRIPTION="Official Sabayon Linux kernel for Amazon EC2 AMI (S3/EBS)"
RESTRICT="mirror"
IUSE="sources_standalone"

DEPEND="${DEPEND}
	sources_standalone? ( !=sys-kernel/linux-ec2-${PVR} )
	!sources_standalone? ( =sys-kernel/linux-ec2-${PVR} )"
