include $(TOPDIR)/rules.mk

PKG_NAME:=openwrt-zeptoclaw
PKG_VERSION:=0.5.9
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/qhkm/zeptoclaw.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)
PKG_MIRROR_HASH:=3e5e9db923020ce6ba04768b5955554bfa4580a0191c373afdccf61e84bf0eae

PKG_MAINTAINER:=yalike
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE
PKG_BUILD_DEPENDS:=rust/host

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

# OpenWrt Rust toolchain defaults to dynamic linking (-crt-static).
# Force static CRT for a standalone zeptoclaw binary.
CARGO_RUSTFLAGS+=-Ctarget-feature=+crt-static
# Ensure libgcc is linked statically as well.
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
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/zeptoclaw $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/zeptoclaw.init $(1)/etc/init.d/zeptoclaw

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/zeptoclaw.config $(1)/etc/config/zeptoclaw
endef

define Package/openwrt-zeptoclaw/conffiles
/etc/config/zeptoclaw
endef

$(eval $(call BuildPackage,openwrt-zeptoclaw))
