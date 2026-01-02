include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-zapret2
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Maxim Onchik <maximonchik78@gmail.com>
PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE

LUCI_TITLE:=Zapret2 Web Interface with Block Check
LUCI_DESCRIPTION:=Complete web interface for zapret2 blocking system with installation, configuration, block lists management, and block testing features.
LUCI_DEPENDS:=+luci-compat +luci-lib-ipkg +curl +wget +tar +jq
LUCI_PKGARCH:=all

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
