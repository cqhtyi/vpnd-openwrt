vpnd
====
Science networking solution for OpenWrt firmware by [MuJJ.us](http://mujj.us)

Build
=====

First, Get OpenWrt's SDK. (e.g. Barrier Breaker and ar71xx)
```
$ wget http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2
$ tar jxf OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2
$ cd OpenWrt-SDK-ar71xx-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2
```

Build the package
```
$ git clone https://github.com/MuJJus/vpnd-openwrt.git package/vpnd
$ make menuconfig    # Selected the package (Network -> vpnd)
$ make package/vpnd/compile V=99
```