include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-zapret2
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=maximonchik78 <your-email@example.com>

LUCI_TITLE:=LuCI Web Interface for Zapret2 with Block Check
LUCI_DESCRIPTION:=Complete web interface for zapret2 with Block Check feature, lists management and statistics
LUCI_DEPENDS:=+luci-compat +luci-lib-ipkg +curl +wget +tar +jq +zapret2
LUCI_PKGARCH:=all
LUCI_PRIORITY:=optional

include $(TOPDIR)/feeds/luci/luci.mk

# Call BuildPackage - OpenWrt build magic
$(eval $(call BuildPackage,$(PKG_NAME)))
