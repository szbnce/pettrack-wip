#!/bin/bash

# PetTrack Manager Script
# Usage:
#   ./manager.sh            # interactive menu
#   ./manager.sh web        # build web dashboard into pettrack_server/static
#   ./manager.sh android    # build Android APK -> PetTrack.apk
#   ./manager.sh ios        # build unsigned IPA -> PetTrack.ipa
#   ./manager.sh all        # web + android + ios
#   ./manager.sh install-android   # adb install PetTrack.apk
#   ./manager.sh install-ios       # open PetTrack.ipa in Sideloadly

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Locate Flutter: prefer PATH, fall back to the usual install location.
if command -v flutter >/dev/null 2>&1; then
    FLUTTER="flutter"
elif [ -x "$HOME/flutter/bin/flutter" ]; then
    FLUTTER="$HOME/flutter/bin/flutter"
else
    echo -e "${RED}Error: flutter not found on PATH or in ~/flutter/bin.${NC}"
    exit 1
fi

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}        PetTrack Project Manager        ${NC}"
echo -e "${CYAN}========================================${NC}"

# Fail loudly instead of copying stale artifacts after a failed build.
run_build() {
    echo -e "${YELLOW}$1${NC}"
    if ! "${@:2}"; then
        echo -e "${RED}Build failed: $1${NC}"
        return 1
    fi
    return 0
}

build_web() {
    echo -e "${YELLOW}Building Web (Static)...${NC}"
    cd pettrack_app || return 1
    if ! run_build "flutter build web --release" "$FLUTTER" build web --release; then
        cd ..
        return 1
    fi
    echo -e "${YELLOW}Deploying to backend...${NC}"
    rm -rf ../pettrack_server/static
    cp -r build/web ../pettrack_server/static
    cd ..
    echo -e "${GREEN}Web Build Complete!${NC}"
}

build_android() {
    echo -e "${YELLOW}Building Android (APK)...${NC}"
    cd pettrack_app || return 1
    if ! run_build "flutter build apk --release" "$FLUTTER" build apk --release; then
        cd ..
        return 1
    fi
    cp build/app/outputs/flutter-apk/app-release.apk ../PetTrack.apk
    cd ..
    echo -e "${GREEN}Android Build Complete! (PetTrack.apk)${NC}"
}

build_ios() {
    echo -e "${YELLOW}Building iOS (Unsigned IPA)...${NC}"
    cd pettrack_app || return 1
    if ! run_build "flutter build ios --release --no-codesign" \
        "$FLUTTER" build ios --release --no-codesign; then
        cd ..
        return 1
    fi
    echo -e "${YELLOW}Packaging IPA...${NC}"
    rm -rf build/ios/Payload build/ios/Runner.app.dSYM
    mkdir -p build/ios/Payload
    cp -R build/ios/iphoneos/Runner.app build/ios/Payload/
    # The zip must contain Payload/Runner.app at its root - that is what
    # Sideloadly / AltStore expect in an .ipa.
    rm -f ../PetTrack.ipa
    (cd build/ios && zip -qr ../../../PetTrack.ipa Payload)
    rm -rf build/ios/Payload
    cd ..
    echo -e "${GREEN}iOS Build Complete! (PetTrack.ipa)${NC}"
}

install_android() {
    echo -e "${YELLOW}Installing to connected Android device...${NC}"
    if [ ! -f "PetTrack.apk" ]; then
        echo -e "${RED}Error: PetTrack.apk not found. Build it first!${NC}"
        return
    fi
    if adb install -r PetTrack.apk; then
        echo -e "${GREEN}Android Installation Complete!${NC}"
    else
        echo -e "${RED}Android Installation Failed! (Is USB debugging enabled?)${NC}"
    fi
}

install_ios() {
    echo -e "${YELLOW}Opening Sideloadly for iOS Installation...${NC}"
    if [ ! -f "PetTrack.ipa" ]; then
        echo -e "${RED}Error: PetTrack.ipa not found. Build it first!${NC}"
        return
    fi
    if open -a Sideloadly PetTrack.ipa; then
        echo -e "${GREEN}Sideloadly opened! Follow the instructions there.${NC}"
    else
        echo -e "${RED}Error: Could not open Sideloadly. Is it installed?${NC}"
    fi
}

show_menu() {
    echo ""
    echo "1) Build Web"
    echo "2) Build Android (APK)"
    echo "3) Build iOS (IPA)"
    echo "4) Build EVERYTHING (Web + Android + iOS)"
    echo "5) Install Android via ADB"
    echo "6) Install iOS via Sideloadly"
    echo "7) Exit"
    echo ""
    read -r -p "Select an option [1-7]: " choice

    case $choice in
        1) build_web; show_menu ;;
        2) build_android; show_menu ;;
        3) build_ios; show_menu ;;
        4) build_web; build_android; build_ios; show_menu ;;
        5) install_android; show_menu ;;
        6) install_ios; show_menu ;;
        7) echo -e "${CYAN}Bye!${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}"; show_menu ;;
    esac
}

# Non-interactive mode: ./manager.sh <target>
case "${1:-menu}" in
    web) build_web ;;
    android) build_android ;;
    ios) build_ios ;;
    all) build_web && build_android && build_ios ;;
    install-android) install_android ;;
    install-ios) install_ios ;;
    menu) show_menu ;;
    *) echo -e "${RED}Unknown target: $1${NC}"; echo "Use: web | android | ios | all | install-android | install-ios"; exit 1 ;;
esac
