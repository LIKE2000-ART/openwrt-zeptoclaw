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
RUST_PKG_LOCKED:=0

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
endef

define Package/openwrt-zeptoclaw/conffiles
/etc/config/zeptoclaw
endef

$(eval $(call BuildPackage,openwrt-zeptoclaw))
