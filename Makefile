# Copyright (C) 2024-2026 Zapret2-Luci-Universe
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-zapret2
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=maximonchik78 <markov7878max@gmail.com>

LUCI_TITLE:=LuCI Web Interface for Zapret2
LUCI_DESCRIPTION:=User-friendly web interface for zapret2 with Block Check feature
LUCI_DEPENDS:=+luci-compat +luci-lib-ipkg +curl +wget +tar +jq
LUCI_PKGARCH:=all
LUCI_PRIORITY:=optional

include $(TOPDIR)/feeds/luci/luci.mk

# Call BuildPackage - OpenWrt build magic
$(eval $(call BuildPackage,$(PKG_NAME)))
