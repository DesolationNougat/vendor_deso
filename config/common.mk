PRODUCT_BRAND ?= DesolationROM

PRODUCT_BUILD_PROP_OVERRIDES += BUILD_UTC_DATE=0

ifeq ($(PRODUCT_GMS_CLIENTID_BASE),)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=android-google
else
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=$(PRODUCT_GMS_CLIENTID_BASE)
endif

PRODUCT_PROPERTY_OVERRIDES += \
    keyguard.no_require_sim=true

PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.selinux=1

# Default notification/alarm sounds
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.notification_sound=Argon.ogg \
    ro.config.alarm_alert=Hassium.ogg

ifneq ($(TARGET_BUILD_VARIANT),user)
# Thank you, please drive thru!
PRODUCT_PROPERTY_OVERRIDES += persist.sys.dun.override=0
endif

ifneq ($(TARGET_BUILD_VARIANT),userdebug)
ifneq ($(TARGET_BUILD_VARIANT),eng)
# Enable ADB authentication
ADDITIONAL_DEFAULT_PROPERTIES += ro.adb.secure=1
endif
endif

ifeq ($(BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE),)
  PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.device.cache_dir=/data/cache
else
  PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    ro.device.cache_dir=/cache
endif

# Backup Tool
PRODUCT_COPY_FILES += \
    vendor/deso/prebuilt/common/bin/backuptool.sh:install/bin/backuptool.sh \
    vendor/deso/prebuilt/common/bin/backuptool.functions:install/bin/backuptool.functions \
    vendor/deso/prebuilt/common/bin/50-deso.sh:system/addon.d/50-deso.sh \
    vendor/deso/prebuilt/common/bin/blacklist:system/addon.d/blacklist

# Backup Services whitelist
PRODUCT_COPY_FILES += \
    vendor/deso/config/permissions/backup.xml:system/etc/sysconfig/backup.xml

# init.d support
PRODUCT_COPY_FILES += \
    vendor/deso/prebuilt/common/bin/sysinit:system/bin/sysinit

ifneq ($(TARGET_BUILD_VARIANT),user)
# userinit support
PRODUCT_COPY_FILES += \
    vendor/deso/prebuilt/common/etc/init.d/90userinit:system/etc/init.d/90userinit
endif

# Desolation specific init file
PRODUCT_COPY_FILES += \
    vendor/deso/prebuilt/common/etc/init.local.rc:root/init.deso.rc

# Copy over added mimetype supported in libcore.net.MimeUtils
PRODUCT_COPY_FILES += \
    vendor/deso/prebuilt/common/lib/content-types.properties:system/lib/content-types.properties

# Enable SIP+VoIP on all targets
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml

# Enable wireless Xbox 360 controller support
PRODUCT_COPY_FILES += \
    frameworks/base/data/keyboards/Vendor_045e_Product_028e.kl:system/usr/keylayout/Vendor_045e_Product_0719.kl

# Include Desolation audio files
include vendor/deso/config/deso_audio.mk

# TWRP
ifeq ($(WITH_TWRP),true)
include vendor/deso/config/twrp.mk
endif

# Required packages
PRODUCT_PACKAGES += \
    BluetoothExt

# Optional packages
PRODUCT_PACKAGES += \
    libemoji \
    LiveWallpapersPicker

# Include explicitly to work around GMS issues
PRODUCT_PACKAGES += \
    libprotobuf-cpp-full \
    librsjni

# Custom packages
PRODUCT_PACKAGES += \
    ExactCalculator \
    Gallery2

# Exchange support
PRODUCT_PACKAGES += \
    Exchange2

# Extra tools
PRODUCT_PACKAGES += \
    libsepol \
    gdbserver \
    micro_bench \
    mke2fs \
    oprofiled \
    powertop \
    sqlite3 \
    strace \
    tune2fs

# ExFAT support
WITH_EXFAT ?= true
ifeq ($(WITH_EXFAT),true)
TARGET_USES_EXFAT := true
PRODUCT_PACKAGES += \
    mount.exfat \
    fsck.exfat \
    mkfs.exfat
endif

# Storage manager
PRODUCT_PROPERTY_OVERRIDES += \
    ro.storage_manager.enabled=true

# These packages are excluded from user builds
ifneq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_PACKAGES += \
    procmem \
    procrank
endif

DEVICE_PACKAGE_OVERLAYS += vendor/deso/overlay/common

# Boot animation
ifneq ($(TARGET_SCREEN_WIDTH) $(TARGET_SCREEN_HEIGHT),$(space))

# determine the smaller dimension
TARGET_BOOTANIMATION_SIZE := $(shell \
  if [ $(TARGET_SCREEN_WIDTH) -lt $(TARGET_SCREEN_HEIGHT) ]; then \
    echo $(TARGET_SCREEN_WIDTH); \
  else \
    echo $(TARGET_SCREEN_HEIGHT); \
  fi )

# get a sorted list of the sizes
bootanimation_sizes := $(subst .zip,, $(shell ls vendor/deso/prebuilt/common/bootanimation))
bootanimation_sizes := $(shell echo -e $(subst $(space),'\n',$(bootanimation_sizes)) | sort -rn)

# find the appropriate size and set
define check_and_set_bootanimation
$(eval TARGET_BOOTANIMATION_NAME := $(shell \
  if [ -z "$(TARGET_BOOTANIMATION_NAME)" ]; then
    if [ $(1) -le $(TARGET_BOOTANIMATION_SIZE) ]; then \
      echo $(1); \
      exit 0; \
    fi;
  fi;
  echo $(TARGET_BOOTANIMATION_NAME); ))
endef
$(foreach size,$(bootanimation_sizes), $(call check_and_set_bootanimation,$(size)))

ifeq ($(TARGET_BOOTANIMATION_HALF_RES),true)
PRODUCT_COPY_FILES += \
    vendor/deso/prebuilt/common/bootanimation/halfres/$(TARGET_BOOTANIMATION_NAME).zip:system/media/bootanimation.zip
else
PRODUCT_COPY_FILES += \
    vendor/deso/prebuilt/common/bootanimation/$(TARGET_BOOTANIMATION_NAME).zip:system/media/bootanimation.zip
endif
endif

PRODUCT_VERSION_MAJOR = 1
PRODUCT_VERSION_MINOR = 0
PRODUCT_VERSION_MAINTENANCE := 0

ifeq ($(TARGET_VENDOR_SHOW_MAINTENANCE_VERSION),true)
    DESO_VERSION_MAINTENANCE := $(PRODUCT_VERSION_MAINTENANCE)
else
    DESO_VERSION_MAINTENANCE := 0
endif

# Filter out random types, so it'll reset to UNOFFICIAL
ifeq ($(filter RELEASE NIGHTLY SNAPSHOT EXPERIMENTAL,$(DESO_BUILDTYPE)),)
    DESO_BUILDTYPE :=
endif

ifdef DESO_BUILDTYPE
    ifneq ($(DESO_BUILDTYPE), SNAPSHOT)
        ifdef DESO_EXTRAVERSION
            # Force build type to EXPERIMENTAL
            DESO_BUILDTYPE := EXPERIMENTAL
            # Remove leading dash from DESO_EXTRAVERSION
            DESO_EXTRAVERSION := $(shell echo $(DESO_EXTRAVERSION) | sed 's/-//')
            # Add leading dash to DESO_EXTRAVERSION
            DESO_EXTRAVERSION := -$(DESO_EXTRAVERSION)
        endif
    else
        ifndef DESO_EXTRAVERSION
            # Force build type to EXPERIMENTAL, SNAPSHOT mandates a tag
            DESO_BUILDTYPE := EXPERIMENTAL
        else
            # Remove leading dash from DESO_EXTRAVERSION
            DESO_EXTRAVERSION := $(shell echo $(DESO_EXTRAVERSION) | sed 's/-//')
            # Add leading dash to DESO_EXTRAVERSION
            DESO_EXTRAVERSION := -$(DESO_EXTRAVERSION)
        endif
    endif
else
    # If DESO_BUILDTYPE is not defined, set to UNOFFICIAL
    DESO_BUILDTYPE := UNOFFICIAL
    DESO_EXTRAVERSION :=
endif

ifeq ($(DESO_BUILDTYPE), UNOFFICIAL)
    ifneq ($(TARGET_UNOFFICIAL_BUILD_ID),)
        DESO_EXTRAVERSION := -$(TARGET_UNOFFICIAL_BUILD_ID)
    endif
endif

ifeq ($(DESO_BUILDTYPE), RELEASE)
    ifndef TARGET_VENDOR_RELEASE_BUILD_ID
        DESO_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR).$(PRODUCT_VERSION_MAINTENANCE)$(PRODUCT_VERSION_DEVICE_SPECIFIC)-$(DESO_BUILD)
    else
        ifeq ($(TARGET_BUILD_VARIANT),user)
            ifeq ($(DESO_VERSION_MAINTENANCE),0)
                DESO_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(TARGET_VENDOR_RELEASE_BUILD_ID)-$(DESO_BUILD)
            else
                DESO_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR).$(DESO_VERSION_MAINTENANCE)-$(TARGET_VENDOR_RELEASE_BUILD_ID)-$(DESO_BUILD)
            endif
        else
            DESO_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR).$(PRODUCT_VERSION_MAINTENANCE)$(PRODUCT_VERSION_DEVICE_SPECIFIC)-$(DESO_BUILD)
        endif
    endif
else
    ifeq ($(DESO_VERSION_MAINTENANCE),0)
        DESO_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(shell date -u +%Y%m%d)-$(DESO_BUILDTYPE)$(DESO_EXTRAVERSION)-$(DESO_BUILD)
    else
        DESO_VERSION := $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR).$(DESO_VERSION_MAINTENANCE)-$(shell date -u +%Y%m%d)-$(DESO_BUILDTYPE)$(DESO_EXTRAVERSION)-$(DESO_BUILD)
    endif
endif

PRODUCT_PROPERTY_OVERRIDES += \
    ro.deso.version=$(DESO_VERSION) \
    ro.deso.releasetype=$(DESO_BUILDTYPE) \
    ro.deso.build.version=$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR) \
    ro.modversion=$(DESO_VERSION)

DESO_DISPLAY_VERSION := $(DESO_VERSION)

PRODUCT_PROPERTY_OVERRIDES += \
    ro.deso.display.version=$(DESO_DISPLAY_VERSION)

-include $(WORKSPACE)/build_env/image-auto-bits.mk
-include vendor/deso/config/partner_gms.mk

$(call prepend-product-if-exists, vendor/extra/product.mk)
