vpnd
====
Science networking solution for OpenWrt firmware by [MuJJ.us](http://mujj.us)

> System Requirement for OpenWrt Barrier Breaker 14.07 or later version.

Usage
=====
Use vpnd only four steps:

1. Build the package or download prebuilt package and install it.
2. Reboot your router.
3. Change DNS settings to ```127.0.0.1#5353``` on your router.
4. Settings your PPTP server address/username/password in ```mujjus``` interface then connect it.
5. Enjoy the internet without Firewall!

Dependencies
============
* [ChinaDNS](https://github.com/aa65535/openwrt-chinadns)
* [openwrt-dist-luci](https://github.com/aa65535/openwrt-dist-luci)

Build
=====

First, Get the OpenWrt's SDK. (e.g. Barrier Breaker and ar71xx)
```
$ wget http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2
$ tar jxf OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2
$ cd OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2
```

Build the package
```
$ git clone https://github.com/MuJJus/vpnd-openwrt.git package/vpnd
$ make menuconfig    # Selected the package (Network -> Routing and Redirection -> vpnd)
$ make package/vpnd/compile V=99
```

* [Prebuilt Packages on Barrier Breaker 14.07](http://dl.mujj.us/openwrt/)

Q&A
===

1. **Can use other VPN protocols?**  
   Yes, it support any based Point-to-Point protocols like PPPoE, PPTP and L2TP.

2. **How to use One-key upgrade in luci-app-commands?**  
   Add [this](http://dl.mujj.us/openwrt/) packages repository to ```/etc/opkg.conf```.

3. **Click Run button of vpnd upgrade in luci-app-commands then very very long loading time.**  
   Your network has encountered a problem, try again later.

4. **Click Run button of vpnd upgrade in luci-app-commands then show me a error: Could not lock /var/lock/opkg.lock: Resource temporarily unavailable.**  
   Try again later. If this error message persists please reboot your router.

5. **An error when installing: But that file is already provided by package * dnsmasq.**  
   Remove dnsmasq package first. (Don't stop dnsmasq service)

6. **Why transparent proxy feature does not work?**  
   You need install ```iptables-mod-nat-extra``` package.
