include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-zapret2
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=maximonchik78

LUCI_TITLE:=LuCI Web Interface for Zapret2
LUCI_DEPENDS:=+luci-compat +luci-lib-ipkg +zapret2
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,$(PKG_NAME)))
