include $(TOPDIR)/rules.mk

PKG_NAME:=vpnd
PKG_VERSION:=0.2
PKG_RELEASE:=2
PKG_MAINTAINER:=Jason Tse <jasontsecode@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/vpnd
   SECTION:=net
   CATEGORY:=Network
   SUBMENU:=Routing and Redirection
   DEPENDS:=+dnsmasq-full +ip +ipset +ppp-mod-pptp +iptables +iptables-mod-u32 +iptables-mod-ipopt +iptables-mod-nat-extra
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
	$(INSTALL_CONF) ./files/mujj.rtbl $(1)/etc/mujjus/
	$(INSTALL_CONF) ./files/firewall $(1)/etc/mujjus/
	$(INSTALL_CONF) ./files/servers.conf $(1)/etc/mujjus/dnsmasq.d/
	$(INSTALL_CONF) ./files/ipset.conf $(1)/etc/mujjus/dnsmasq.d/
	$(INSTALL_BIN) ./files/mujjus-ip-up $(1)/etc/ppp/ip-up.d/
	$(INSTALL_BIN) ./files/mujjus-ip-down $(1)/etc/ppp/ip-down.d/
	$(INSTALL_BIN) ./files/35-mujjus $(1)/etc/hotplug.d/iface/
endef

define Package/vpnd/postinst
#!/bin/sh
echo "conf-dir=/etc/mujjus/dnsmasq.d" >> /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart
uci add firewall include
uci set firewall.@include[-1].path=/etc/mujjus/firewall
uci commit firewall
/etc/init.d/firewall reload
uci show network | grep -q "^network.mujjus"
if [ "$$?" -ne "0" ]; then
    uci set network.mujjus=interface
    uci set network.mujjus.proto=pptp
    uci set network.mujjus.server=fc.mujj.us
    uci set network.mujjus.defaultroute=0
    uci set network.mujjus.peerdns=0
    uci set network.mujjus.keepalive="3 10"
    uci set network.mujjus.mtu=1400
    uci get firewall.@zone[1].network | grep -q mujjus
    if [ "$$?" -ne "0" ]; then
        WANZONE=`uci get firewall.@zone[1].network`
        uci set firewall.@zone[1].network="$$WANZONE mujjus"
    fi
    uci commit network
    /etc/init.d/network reload
fi
endef

define Package/vpnd/postrm
#!/bin/sh
sed -i '/^conf-dir=\/etc\/mujjus\/dnsmasq.d$/d' /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart
FWINDEX = `uci show firewall | grep firewall.@include | grep /etc/mujjus/firewall | cut -c 19`
uci delete firewall.@include[$$FWINDEX]
uci commit firewall
/etc/init.d/firewall restart
endef

define Build/Compile
endef

$(eval $(call BuildPackage,vpnd))
