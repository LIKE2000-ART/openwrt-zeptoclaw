include $(TOPDIR)/rules.mk

PKG_NAME:=openwrt-zeptoclaw
PKG_VERSION:=0.6.1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/qhkm/zeptoclaw.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)
PKG_MIRROR_HASH:=8bf1d73e6d19a307ff3f25d83ac01a625533a4e18af12261ccdaaa391efced62

PKG_MAINTAINER:=yalike
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE
PKG_BUILD_DEPENDS:=rust/host
PKG_USE_MIPS16:=0

# Only MIPS targets need the portable-atomic patch and unlocked Cargo resolution.
ifneq ($(filter mips mipsel,$(ARCH)),)
RUST_PKG_LOCKED:=0
define Build/Patch
	$(call Build/Patch/Default)
endef
else
define Build/Patch
	:
endef
endif

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

# Speed up CI compile time for large Rust dependency graph.
# Tradeoff: slightly larger binary compared to OpenWrt's default rust profile.
CARGO_PKG_VARS+= \
	CARGO_PROFILE_RELEASE_LTO=false \
	CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 \
	CARGO_PROFILE_RELEASE_OPT_LEVEL=2

# Keep OpenWrt default crt behavior for compatibility, but statically link libgcc.
CARGO_RUSTFLAGS+=-Clink-arg=-static-libgcc

# psm's MIPS asm does not support being built with mips16 flags.
TARGET_CFLAGS:=$(filter-out -mips16 -minterlink-mips16,$(TARGET_CFLAGS))
TARGET_CXXFLAGS:=$(filter-out -mips16 -minterlink-mips16,$(TARGET_CXXFLAGS))

define Package/openwrt-zeptoclaw
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=ZeptoClaw ultra-lightweight personal AI assistant
  URL:=https://github.com/qhkm/zeptoclaw
  DEPENDS:=+ca-bundle +ca-certificates
endef

define Package/openwrt-zeptoclaw/description
 A cross-compiled OpenWrt package for ZeptoClaw.
endef

# Build only the CLI binary from this workspace.
CARGO_BUILD_BINARIES:=zeptoclaw

define Package/openwrt-zeptoclaw/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/bin/zeptoclaw $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/zeptoclaw.init $(1)/etc/init.d/zeptoclaw

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/zeptoclaw.config $(1)/etc/config/zeptoclaw

	$(INSTALL_DIR) $(1)/usr/share/zeptoclaw
	$(INSTALL_DATA) ./files/zeptoclaw-config.json $(1)/usr/share/zeptoclaw/config.json
endef

define Package/openwrt-zeptoclaw/conffiles
/etc/config/zeptoclaw
endef

define Package/openwrt-zeptoclaw/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0

default_workdir="/root/.zeptoclaw"
workdir="$$(uci -q get zeptoclaw.main.workdir)"
[ -n "$$workdir" ] || workdir="$$default_workdir"
cfg_dir="/etc/zeptoclaw"
cfg_master="$$cfg_dir/config.json"
cfg_workdir="$$workdir/config.json"
cfg_default="$$default_workdir/config.json"

mkdir -p "$$cfg_dir" "$$workdir" "$$workdir/workspace" "$$workdir/sessions"

# Keep upstream default path consistent at install time:
# /root/.zeptoclaw -> $$workdir (when workdir is customized).
if [ "$$workdir" != "$$default_workdir" ]; then
	if [ -L "$$default_workdir" ]; then
		if [ "$$(readlink "$$default_workdir")" != "$$workdir" ]; then
			rm -f "$$default_workdir"
			ln -s "$$workdir" "$$default_workdir"
		fi
	elif [ -d "$$default_workdir" ]; then
		# One-time migration if old default dir already has data.
		cp -a "$$default_workdir"/. "$$workdir"/ 2>/dev/null || true
		rm -rf "$$default_workdir"
		ln -s "$$workdir" "$$default_workdir"
	elif [ -e "$$default_workdir" ]; then
		rm -f "$$default_workdir"
		ln -s "$$workdir" "$$default_workdir"
	else
		ln -s "$$workdir" "$$default_workdir"
	fi
fi

# Initialize master config only once.
if [ ! -f "$$cfg_master" ] && [ -f /usr/share/zeptoclaw/config.json ]; then
	cp /usr/share/zeptoclaw/config.json "$$cfg_master"
	chmod 600 "$$cfg_master"
fi

# Keep runtime config path as symlink to the master file.
if [ -L "$$cfg_workdir" ]; then
	if [ "$$(readlink "$$cfg_workdir")" != "$$cfg_master" ]; then
		rm -f "$$cfg_workdir"
		ln -s "$$cfg_master" "$$cfg_workdir"
	fi
elif [ -f "$$cfg_workdir" ]; then
	if [ ! -e "$$cfg_master" ]; then
		mv "$$cfg_workdir" "$$cfg_master"
	else
		rm -f "$$cfg_workdir"
	fi
	ln -s "$$cfg_master" "$$cfg_workdir"
elif [ ! -e "$$cfg_workdir" ]; then
	ln -s "$$cfg_master" "$$cfg_workdir"
fi

# Also keep default path config entry available:
# /root/.zeptoclaw/config.json -> /etc/zeptoclaw/config.json
# If /root/.zeptoclaw is already a symlink to workdir, this naturally resolves
# through the same cfg_workdir link above.
if [ -d "$$default_workdir" ] && [ ! -L "$$default_workdir" ]; then
	if [ -L "$$cfg_default" ]; then
		if [ "$$(readlink "$$cfg_default")" != "$$cfg_master" ]; then
			rm -f "$$cfg_default"
			ln -s "$$cfg_master" "$$cfg_default"
		fi
	elif [ -f "$$cfg_default" ]; then
		if [ ! -e "$$cfg_master" ]; then
			mv "$$cfg_default" "$$cfg_master"
		else
			rm -f "$$cfg_default"
		fi
		ln -s "$$cfg_master" "$$cfg_default"
	elif [ ! -e "$$cfg_default" ]; then
		ln -s "$$cfg_master" "$$cfg_default"
	fi
fi

exit 0
endef

define Package/openwrt-zeptoclaw/prerm
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0

# Uninstall path: avoid noisy procd "service delete ... Not found" messages.
if [ -x /etc/init.d/zeptoclaw ]; then
	/etc/init.d/zeptoclaw stop >/dev/null 2>&1 || true
	/etc/init.d/zeptoclaw disable >/dev/null 2>&1 || true
fi

exit 0
endef

$(eval $(call BuildPackage,openwrt-zeptoclaw))
