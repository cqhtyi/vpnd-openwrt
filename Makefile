include $(TOPDIR)/rules.mk

PKG_NAME:=vpnd
PKG_VERSION:=1.0.2
PKG_RELEASE:=1
PKG_MAINTAINER:=Jason Tse <jasontsecode@gmail.com>
PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/vpnd
   SECTION:=net
   CATEGORY:=Network
   SUBMENU:=Routing and Redirection
   DEPENDS:=+dnsmasq-full +ip +ipset +ppp-mod-pptp +iptables +iptables-mod-ipopt +kmod-ipt-nathelper-extra +luci-app-commands +ChinaDNS +luci-app-chinadns
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
	$(INSTALL_CONF) ./files/servers.conf $(1)/etc/mujjus/dnsmasq.d/
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
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/35-mujjus $(1)/etc/hotplug.d/iface/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/vpnd.init $(1)/etc/init.d/vpnd
endef

define Package/vpnd/preinst
#!/bin/sh
ifdown mujjus >/dev/null
endef

define Package/vpnd/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-vpnd ) && rm -f /etc/uci-defaults/luci-vpnd
fi
/etc/init.d/vpnd enable
/etc/init.d/chinadns start
/etc/init.d/chinadns enable
if ! grep -q ^100[[:space:]]mujj$$ /etc/iproute2/rt_tables; then
    echo -e "100\tmujj" >> /etc/iproute2/rt_tables
fi
if ! grep -q conf-dir=/etc/mujjus/dnsmasq.d /etc/dnsmasq.conf; then
    echo "conf-dir=/etc/mujjus/dnsmasq.d" >> /etc/dnsmasq.conf
fi
/etc/init.d/dnsmasq restart
if ! uci show luci | grep luci.@command | grep .name | grep -q vpnd; then
    uci add luci command
    uci set luci.@command[-1].name=vpnd
    uci set luci.@command[-1].command="/bin/vpnd upgrade"
    uci commit luci
fi
if ! uci show network | grep -q "^network.mujjus"; then
    uci set network.mujjus=interface
    uci set network.mujjus.proto=pptp
    uci set network.mujjus.defaultroute=0
    uci set network.mujjus.peerdns=0
    uci set network.mujjus.keepalive="3 10"
    uci set network.mujjus.mtu=1400
    uci set network.mujjus.pppd_options="refuse-eap refuse-pap refuse-chap refuse-mschap"
    if ! uci get firewall.@zone[1].network | grep -q mujjus; then
        WANZONE=`uci get firewall.@zone[1].network`
        uci set firewall.@zone[1].network="$$WANZONE mujjus"
    fi
    uci commit network
    /etc/init.d/network reload
fi
if ! uci show firewall | grep firewall.@include | grep -q /etc/mujjus/firewall; then
    uci add firewall include
    uci set firewall.@include[-1].path=/etc/mujjus/firewall
fi
uci commit firewall
/etc/init.d/firewall restart
ifup mujjus >/dev/null
endef

define Package/vpnd/postrm
#!/bin/sh
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
