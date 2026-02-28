include $(TOPDIR)/rules.mk

PKG_NAME:=openwrt-zeptoclaw
PKG_VERSION:=0.6.1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/qhkm/zeptoclaw.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)
PKG_MIRROR_HASH:=c8aef5a21b2e042c4041b5a227443e041e9fe5999feb17950a268c61e006455e

PKG_MAINTAINER:=yalike
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE
PKG_BUILD_DEPENDS:=rust/host
PKG_USE_MIPS16:=0

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
endef

define Package/openwrt-zeptoclaw/conffiles
/etc/config/zeptoclaw
endef

$(eval $(call BuildPackage,openwrt-zeptoclaw))
