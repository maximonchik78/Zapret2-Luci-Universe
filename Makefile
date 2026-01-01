include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-zapret2
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Zapret2 Team <zapret@example.com>
PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE

LUCI_TITLE:=Zapret2 Web Interface with Block Check
LUCI_DESCRIPTION:=A complete web interface for zapret2 with installation, block check, and management features
LUCI_DEPENDS:=+luci-compat +luci-lib-ipkg +curl +wget +tar +jq +zapret
LUCI_PKGARCH:=all

PKG_BUILD_DEPENDS:=luci/host

include ../../luci.mk

define Package/luci-app-zapret2/conffiles
/etc/config/zapret2
/etc/zapret/
endef

# call BuildPackage - OpenWrt buildroot signature
