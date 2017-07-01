export TARGET = iphone:10.1:9.0

# we’re only supporting arm64. sorry
export ARCHS = arm64

INSTALL_TARGET_PROCESSES = Preferences CanzoneNowPlayingWidget CanzoneNotificationContent

ifneq ($(RESPRING),0)
INSTALL_TARGET_PROCESSES += SpringBoard
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Canzone
Canzone_FILES = $(wildcard *.x) $(wildcard *.m)
Canzone_FRAMEWORKS = UIKit
Canzone_PRIVATE_FRAMEWORKS = BulletinBoard MediaPlayerUI MediaRemote
Canzone_EXTRA_FRAMEWORKS = Cephei
Canzone_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

ifneq ($(TARGET),simulator)
SUBPROJECTS += widget notification-content prefs postinst app
include $(THEOS_MAKE_PATH)/aggregate.mk
endif

after-install::
ifeq ($(RESPRING),0)
	#install.exec "uiopen prefs:root=Canzone"
endif
	install.exec "killall -KILL CanzoneNotificationContent; killall -KILL CanzoneNotificationContent"
