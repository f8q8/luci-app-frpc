#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-frpc
PKG_VERSION:=1
PKG_RELEASE:=4
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

PO2LMO:=$(TOPDIR)/package/luci-app-frpc/tools/po2lmo/src/po2lmo

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  DEPENDS:=
  TITLE:=luci-app-frpc
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
 frpc web UI
endef

define Build/Compile
endef

define Build/Prepare
 #       $(foreach po,$(wildcard ${CURDIR}/po/zh-cn/frp.zh-cn.po), \
 #               po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh 
[ -n "$${IPKG_INSTROOT}" ] || {
	( . /etc/uci-defaults/luci-frp ) && rm -f /etc/uci-defaults/luci-frp
	/etc/init.d/frp enable >/dev/null 2>&1
	exit 0
}
endef

define Package/$(PKG_NAME)/install
	$(CP) ./root/* $(1)
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(PO2LMO) ./po/zh-cn/frp.zh-cn.po $(1)/usr/lib/lua/luci/i18n/frp.zh-cn.lmo
       # $(INSTALL_DATA) $(PKG_BUILD_DIR)/frp.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/
	$(CP) ./luasrc/* $(1)/usr/lib/lua/luci
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
