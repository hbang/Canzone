export TARGET = iphone:10.1:10.0

# since this is for iOS 10 only, and there isn’t a jailbreak for 32-bit devices yet, cheat a bit
# and only build for arm64
export ARCHS = arm64

INSTALL_TARGET_PROCESSES = Preferences CanzoneNowPlayingWidget CanzoneNotificationContent

ifneq ($(RESPRING),0)
INSTALL_TARGET_PROCESSES += SpringBoard
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Canzone
Canzone_FILES = $(wildcard *.x) $(wildcard *.m)
Canzone_FRAMEWORKS = UIKit
Canzone_PRIVATE_FRAMEWORKS = BulletinBoard MediaRemote
Canzone_EXTRA_FRAMEWORKS = Cephei
Canzone_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

ifneq ($(TARGET),simulator)
SUBPROJECTS += widget notification-content provider prefs postinst app
include $(THEOS_MAKE_PATH)/aggregate.mk
endif

after-install::
ifeq ($(RESPRING),0)
	install.exec "uiopen prefs:root=Canzone"
endif
