# Insert new variables inside the Desolation structure
lineage_soong:
	$(hide) mkdir -p $(dir $@)
	$(hide) (\
	echo '{'; \
	echo '"Desolation": {'; \
	echo '},'; \
	echo '') > $(SOONG_VARIABLES_TMP)
