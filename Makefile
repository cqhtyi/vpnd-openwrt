include $(TOPDIR)/rules.mk

PKG_NAME:=vpnd
PKG_VERSION:=0.5
PKG_RELEASE:=1
PKG_MAINTAINER:=Jason Tse <jasontsecode@gmail.com>
PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/vpnd
   SECTION:=net
   CATEGORY:=Network
   SUBMENU:=Routing and Redirection
   DEPENDS:=+dnsmasq-full +ip +ipset +ppp-mod-pptp +iptables +iptables-mod-u32 +iptables-mod-ipopt +iptables-mod-nat-extra +luci-app-commands
   TITLE:=Smart routing solution by MuJJ.us
   MAINTAINER:=Jason Tse <jasontsecode@gmail.com>
   PKGARCH:=all
endef

define Package/vpnd/description
Smart routing solution by MuJJ.us
endef

define Package/vpnd/install
	$(INSTALL_DIR) $(1)/etc/mujjus/dnsmasq.d
	$(INSTALL_DIR) $(1)/etc/ppp/ip-up.d
	$(INSTALL_DIR) $(1)/etc/ppp/ip-down.d
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_CONF) ./files/mujj.rtbl $(1)/etc/mujjus/
	$(INSTALL_CONF) ./files/firewall $(1)/etc/mujjus/
	$(INSTALL_CONF) ./files/servers.conf $(1)/etc/mujjus/dnsmasq.d/
	$(INSTALL_CONF) ./files/ipset.conf $(1)/etc/mujjus/dnsmasq.d/
	$(INSTALL_BIN) ./files/mujjus-ip-up $(1)/etc/ppp/ip-up.d/
	$(INSTALL_BIN) ./files/mujjus-ip-down $(1)/etc/ppp/ip-down.d/
	$(INSTALL_BIN) ./files/35-mujjus $(1)/etc/hotplug.d/iface/
	$(INSTALL_BIN) ./files/vpnd $(1)/bin/
endef

define Package/vpnd/postinst
#!/bin/sh
if ! grep -q conf-dir=/etc/mujjus/dnsmasq.d /etc/dnsmasq.conf; then
	echo "conf-dir=/etc/mujjus/dnsmasq.d" >> /etc/dnsmasq.conf
fi
/etc/init.d/dnsmasq restart
if ! uci show firewall | grep firewall.@include | grep -q /etc/mujjus/firewall; then
    uci add firewall include
    uci set firewall.@include[-1].path=/etc/mujjus/firewall
    uci commit firewall
fi
/etc/init.d/firewall restart
if ! uci get luci | grep luci.@command | grep .name | grep -q vpnd; then
    uci add luci command
    uci set luci.@command[-1].name=vpnd
    uci set luci.@command[-1].command="/bin/vpnd upgrade"
    uci commit luci
fi
if ! uci show network | grep -q "^network.mujjus"; then
    uci set network.mujjus=interface
    uci set network.mujjus.proto=pptp
    uci set network.mujjus.server=fc.mujj.us
    uci set network.mujjus.defaultroute=0
    uci set network.mujjus.peerdns=0
    uci set network.mujjus.keepalive="3 10"
    uci set network.mujjus.mtu=1400
    if ! uci get firewall.@zone[1].network | grep -q mujjus; then
        WANZONE=`uci get firewall.@zone[1].network`
        uci set firewall.@zone[1].network="$$WANZONE mujjus"
    fi
    uci commit network
    /etc/init.d/network reload
fi
rm -rf /tmp/luci-*
endef

define Package/vpnd/postrm
#!/bin/sh
sed -i '/^conf-dir=\/etc\/mujjus\/dnsmasq.d$/d' /etc/dnsmasq.conf
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
