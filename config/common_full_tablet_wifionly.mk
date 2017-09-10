# Inherit full common Desolation stuff
$(call inherit-product, vendor/deso/config/common_full.mk)

# Required packages
PRODUCT_PACKAGES += \
    LatinIME
