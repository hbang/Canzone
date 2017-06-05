include $(THEOS)/makefiles/common.mk

APPEX_NAME = CanzoneNotificationContent
CanzoneNotificationContent_FILES = $(wildcard *.swift)
CanzoneNotificationContent_INSTALL_PATH = /Applications/Canzone.app/PlugIns
CanzoneNotificationContent_FRAMEWORKS = UserNotifications UserNotificationsUI
CanzoneNotificationContent_PRIVATE_FRAMEWORKS = MediaPlayerUI MediaRemote
CanzoneNotificationContent_EXTRA_FRAMEWORKS = Cephei
CanzoneNotificationContent_SWIFT_BRIDGING_HEADER = ../global/BridgingHeader.h
CanzoneNotificationContent_LDFLAGS = -L.. -lswiftQuartzCore

include $(THEOS_MAKE_PATH)/appex.mk
