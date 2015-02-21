include $(TOPDIR)/rules.mk

PKG_NAME:=vpnd
PKG_VERSION:=1.2.4
PKG_RELEASE:=1
PKG_MAINTAINER:=Jason Tse <jasontsecode@gmail.com>
PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/vpnd
   SECTION:=net
   CATEGORY:=Network
   SUBMENU:=Routing and Redirection
   DEPENDS:=+dnsmasq-full +ip +ipset +ppp-mod-pptp +iptables +iptables-mod-ipopt +luci-app-commands +ChinaDNS +luci-app-chinadns
   TITLE:=Smart routing solution by MuJJ.us
   MAINTAINER:=Jason Tse <jasontsecode@gmail.com>
   PKGARCH:=all
endef

define Package/vpnd/description
Smart routing solution by MuJJ.us
endef

define Package/vpnd/conffiles
/etc/config/vpnd
/etc/mujjus/dnsmasq.d/custom.conf
endef

define Package/vpnd/install
	$(INSTALL_DIR) $(1)/etc/mujjus/dnsmasq.d
	$(INSTALL_DIR) $(1)/etc/ppp/ip-up.d
	$(INSTALL_DIR) $(1)/etc/ppp/ip-down.d
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_CONF) ./files/mujj.rtbl $(1)/etc/mujjus/
	$(INSTALL_CONF) ./files/CN.rtbl $(1)/etc/mujjus/
	$(INSTALL_CONF) ./files/firewall $(1)/etc/mujjus/
	$(INSTALL_CONF) ./files/ipset.conf $(1)/etc/mujjus/dnsmasq.d/
	$(INSTALL_CONF) ./files/custom.conf $(1)/etc/mujjus/dnsmasq.d/
	$(INSTALL_BIN) ./files/mujjus-ip-up $(1)/etc/ppp/ip-up.d/
	$(INSTALL_BIN) ./files/mujjus-ip-down $(1)/etc/ppp/ip-down.d/
	$(INSTALL_BIN) ./files/vpnd $(1)/bin/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/vpnd.config $(1)/etc/config/vpnd
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/vpnd.uci-defaults $(1)/etc/uci-defaults/luci-vpnd
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/vpnd.controller $(1)/usr/lib/lua/luci/controller/vpnd.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/vpnd.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/vpnd.zh-cn.lmo
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/vpnd
	$(INSTALL_DATA) ./files/globals.cbi $(1)/usr/lib/lua/luci/model/cbi/vpnd/globals.lua
	$(INSTALL_DATA) ./files/policies.cbi $(1)/usr/lib/lua/luci/model/cbi/vpnd/policies.lua
	$(INSTALL_DATA) ./files/dnsmasq.cbi $(1)/usr/lib/lua/luci/model/cbi/vpnd/dnsmasq.lua
endef

define Package/vpnd/preinst
#!/bin/sh
[ -z "$$IPKG_INSTROOT" ] && ifdown mujjus >/dev/null
exit 0
endef

define Package/vpnd/postinst
#!/bin/sh
[ ! -z "$${IPKG_INSTROOT}" ] && exit 0
VPND_POSTINST=1
. /etc/uci-defaults/luci-vpnd
rm -f /etc/uci-defaults/luci-vpnd
/etc/init.d/chinadns restart
/etc/init.d/dnsmasq restart
/etc/init.d/network reload
/etc/init.d/firewall restart
ifup mujjus >/dev/null
endef

define Package/vpnd/postrm
#!/bin/sh
[ ! -z "$${IPKG_INSTROOT}" ] && exit 0
sed -i '/^100\tmujj/d' /etc/iproute2/rt_tables
sed -i '/^conf-dir=\/etc\/mujjus\/dnsmasq.d/d' /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart
FWINDEX = `uci show firewall | grep firewall.@include | grep /etc/mujjus/firewall | cut -c 19`
if [ ! -n "$$FWINDEX" ]; then
    uci delete firewall.@include[$$FWINDEX]
    uci commit firewall
    /etc/init.d/firewall restart
fi
UGDINDEX = `uci show luci | grep luci.@command | grep .name | grep vpnd | cut -c 15`
if [ ! -n "$$UGDINDEX" ]; then
    uci delete luci.@command[$$UGDINDEX]
    uci commit luci
fi
endef

define Build/Compile
endef

$(eval $(call BuildPackage,vpnd))
