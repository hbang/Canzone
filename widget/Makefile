TARGET = iphone:10.1:10.0
SDKVERSION = 10.1

include $(THEOS)/makefiles/common.mk

APPEX_NAME = CanzoneNowPlayingWidget
CanzoneNowPlayingWidget_FILES = $(wildcard *.swift)
CanzoneNowPlayingWidget_INSTALL_PATH = /Applications/Canzone.app/PlugIns
CanzoneNowPlayingWidget_FRAMEWORKS = NotificationCenter
CanzoneNowPlayingWidget_PRIVATE_FRAMEWORKS = MediaPlayerUI
CanzoneNowPlayingWidget_EXTRA_FRAMEWORKS = Cephei CydiaSubstrate
CanzoneNowPlayingWidget_SWIFT_BRIDGING_HEADER = ../global/BridgingHeader.h

include $(THEOS_MAKE_PATH)/appex.mk
