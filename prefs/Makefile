include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Canzone
Canzone_FILES = $(wildcard *.m) $(wildcard *.x)
Canzone_INSTALL_PATH = /Library/PreferenceBundles
Canzone_CFLAGS = -fobjc-arc
Canzone_PRIVATE_FRAMEWORKS = Preferences
Canzone_EXTRA_FRAMEWORKS = CydiaSubstrate CepheiPrefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Canzone.plist$(ECHO_END)
