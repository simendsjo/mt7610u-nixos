# Adds support for the wifi dongles using the mt7610u chipset
#
# To use, edit your configuration.nix with the following changes:
#
#    nixpkgs.config = {
#      allowUnfree = true;
#      packageOverrides = pkgs: {
#            # Change the location to where you cloned the file
#            mt7610u = pkgs.callPackage /home/simendsjo/code/mt7610u-nixos/default.nix {};
#          };
#    };
#
#    boot.extraModulePackages = [ pkgs.mt7610u ];
#    boot.initrd.kernelModules = [ "mt7610u_sta"];
#
#
# To make changes:
# 1) Uncomment the with import line below
# 2) Comment out the { stdenv ... line
# 3) Run nix-shell '<nixpkgs>' -A stdenv fetchFromGitHub linuxPackages
# 4) Make changes
# 5) To build: nix-build -K ./default.nix

#with import <nixpkgs> {};
{ stdenv, fetchFromGitHub, linuxPackages }:

let
  version = "3002";
  date = "20130916";
  kernel = linuxPackages.kernel;
in
stdenv.mkDerivation rec {
  name = "mt7610u-${version}-${kernel.modDirVersion}";

  src = fetchFromGitHub {
    owner = "Myria-de";
    repo = "mt7610u_wifi_sta_v3002_dpo_20130916";
    rev = "33d969adb37bd27ca286c8b2e9c343cb03ff64e2";
    sha256 = "1gqd22b2c431grbafnv1z9002skghh0p1wvwai3ql61f44mr10qs";
  };

  hardeningDisable = [ "pic" "format-security" ];

  # Correct nixos kernel path
  makeFlags = "KBASE=${kernel.dev}/lib/modules/${kernel.modDirVersion}";
  patches = [
    # Extra patches copied from Arch AUR: https://aur.archlinux.org/packages/mt7610u_wifi_sta/
    ./0001-fix-compile-against-kernel-4.6.patch
    ./0002-add-tplink-archer-t1u.patch
    # Fix Makefile to use correct nixos kernel path
    ./0003-nixos-makefile-fix.patch
  ];

  # The driver needs some DAT files which needs to point to the package folder
  configurePhase = ''
    echo "Replacing /etc/Wireless with $out/etc/Wireless"
    find . -type f -exec sed -i -e "s|/etc/Wireless|$out/etc/Wireless|g" {} \;
  '';

  installPhase = ''
    # Kernel module
    echo "Installing kernel module"
    install -v -D -m 644 ./os/linux/mt7610u_sta.ko "$out/lib/modules/${kernel.modDirVersion}/drivers/net/wireless/mt7610u_sta.ko"

    # Dat file
    mkdir -p "$out/etc/Wireless/RT2870STA"
    install -v -D -m 644 ./RT2870STA.dat "$out/etc/Wireless/RT2870STA/RT2870STA.dat"
  '';

  meta = {
    description = "Kernel module driver for some MediaTek wireless dongles";
    homepage = https://wikidevi.com/wiki/MediaTek_MT7610U;
    license = stdenv.lib.licenses.unfreeRedistributable;
    maintainers = with stdenv.lib.maintainers; [ ];
    platforms = stdenv.lib.platforms.linux;
  };
}
