include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-zapret2
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=maximonchik78

LUCI_TITLE:=LuCI Web Interface for Zapret2
LUCI_DESCRIPTION:=Complete web interface for zapret2 with Block Check feature. Requires zapret2 installed separately.
LUCI_DEPENDS:=+luci-compat +luci-lib-ipkg +curl +wget +tar +jq
LUCI_PKGARCH:=all
LUCI_PRIORITY:=optional

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
    # Сообщаем, что нужен zapret2
    echo "⚠️  Note: luci-app-zapret2 requires zapret2 to be installed separately."
    echo "   Install zapret2 from: https://github.com/bol-van/zapret2"
    exit 0
}
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
