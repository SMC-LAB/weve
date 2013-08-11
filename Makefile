SOX_BIN        = $(shell which sox)
LAME_BIN       = $(shell which lame)
FAAC_BIN       = $(shell which faac)
OGGENC_BIN     = $(shell which oggenc)
PYTHON_BIN     = $(shell which python)
PERL_BIN       = $(shell which perl)
COUCHAPP_BIN   = $(shell which couchapp)
FS2JSON_BIN    = scripts/fs2json.pl
JSON2COUCH_BIN = scripts/json2couch.pl
COUCH2CSV_BIN  = scripts/couch2csv.pl

OUT_DIR        = out
AUDIO_DIR      = in
AUDIO_EXT      = wav
COUCHAPP_ENV   = default
COUCHAPP_RC    = .couchapprc
COUCHAPP_HOST := $(shell jshon -e env -e $(COUCHAPP_ENV) -e db < $(COUCHAPP_RC) -u | cut -d'/' -f 1,2,3)
COUCHAPP_DB   := $(shell jshon -e env -e $(COUCHAPP_ENV) -e db < $(COUCHAPP_RC) -u | cut -d'/' -f 4)
AUDIO_FILES   := $(wildcard $(AUDIO_DIR)/*$(EXT))
WAV_FILES     := $(patsubst %.$(AUDIO_EXT), %.wav, $(AUDIO_FILES))
MP3_FILES     := $(notdir $(patsubst %.$(AUDIO_EXT), %.mp3, $(AUDIO_FILES)))
M4A_FILES     := $(patsubst %.$(AUDIO_EXT), %.m4a, $(AUDIO_FILES))
OGA_FILES     := $(patsubst %.$(AUDIO_EXT), %.oga, $(AUDIO_FILES))

all: help

# target: help - print this information
help:
	@echo "Usage: make IN=/some/audio/files/dir OUT=/some/output/dir experiment # upload experiment"
	@echo "       make OUT=/some/output/dir analyze                             # download data"
	@echo "       make OUT=/some/output/dir clean                               # delete local data"
	@echo "       make cleanup                                                  # delete remote data"
	@echo
	@egrep "^# target: [^ ]+" [Mm]akefile
	@echo $(MP3_FILES)

# target: list - print the default values for all Make variables
list:
	@echo SOX_BIN=$(SOX_BIN)
	@echo LAME_BIN=$(LAME_BIN)
	@echo FAAC_BIN=$(FAAC_BIN)
	@echo OGGENC_BIN=$(OGGENC_BIN)
	@echo PYTHON_BIN=$(PYTHON_BIN)
	@echo PERL_BIN=$(PERL_BIN)
	@echo COUCHAPP_BIN=$(COUCHAPP_BIN)
	@echo FS2JSON_BIN=$(FS2JSON_BIN)
	@echo JSON2COUCH_BIN=$(JSON2COUCH_BIN)
	@echo COUCH2CSV_BIN=$(COUCH2CSV_BIN)
	@echo OUT_DIR=$(OUT_DIR)
	@echo AUDIO_DIR=$(AUDIO_DIR)
	@echo AUDIO_EXT=$(AUDIO_EXT)
	@echo COUCHAPP_ENV=$(COUCHAPP_ENV)
	@echo COUCHAPP_RC=$(COUCHAPP_RC)
	@echo COUCHAPP_HOST=$(COUCHAPP_HOST)
	@echo COUCHAPP_DB=$(COUCHAPP_DB)
	@echo AUDIO_FILES=$(AUDIO_FILES)

# target: experiment - prepare local filesystem, generate and upload design document
experiment: dir convert design deploy upload

# target: analyze - dump participants and ratings as a repeated measures/within-subjects csv document
analyze: participants ratings table

# target: cleanup - delete participant and ratings data from the server
cleanup: delete-participants delete-ratings

# target: clean - delete local output directory
clean:
	rm -rf $(OUT_DIR)

# target: check - ensure all dependencies are met
check: $(SOX_BIN) $(LAME_BIN) $(FAAC_BIN) $(OGGENC_BIN) $(PYTHON_BIN) $(PERL_BIN) $(COUCHAPP_BIN) $(FS2JSON_BIN) $(JSON2COUCH_BIN) $(COUCH2CSV_BIN)
	@$(PERL_BIN) -c $(FS2JSON_BIN)
	@$(PERL_BIN) -c $(JSON2COUCH_BIN)
	@$(PERL_BIN) -c $(COUCH2CSV_BIN)

# target: dir - create local experiment filesystem
dir:
	mkdir -p $(OUT_DIR)/{audio,participants,ratings}

# target: convert - convert audio files from $IN directory to wav, mp3, m4a, and oga
convert: $(MP3_FILES)

$(MP3_FILES): $(OUT_DIR)/out/%.mp3: $(AUDIO_DIR)/%.wav
	@echo lame -b 256 $< $@

# target: design - generate couchdb design document from local filesystem
design:
	perl scripts/fs2json.pl -a audio=$(OUT/audio) -o $(OUT)/design.json

# target: deploy - upload the weve design document to the server
deploy:
	couchapp push $(COUCHAPP_ENV)

# target: upload - upload audio files as attachments to the server
upload:
	perl scripts/json2couch.pl -i $(OUT)/design.json -u $(COUCHAPP_HOST) -d $(COUCHAPP_DB) -a

# target: participants - dump series of participant data as JSON documents
participants:
	curl -s "$(COUCHAPP_HOST)/_users/_all_docs" | \
	jshon -e rows -a -e id | \
	sed 's/"//g' | \
	perl -ne 'print if m/:\w{40}/' | \
	while read i; do \
	    curl -s "$(COUCHAPP_HOST)/_users/$$i" > \
	    $(OUT)/participants/$$i.json; \
	done

# target: ratings - dump series of ratings data as JSON documents
ratings:
	curl -s "$(COUCHAPP_HOST)/$(COUCHAPP_DB)/_all_docs" | \
	jshon -e rows -a -e id | \
	perl -ne 's/"//g; print unless m/^_/' | \
	while read i; do \
	    curl -s "$(COUCHAPP_HOST)/$(COUCHAPP_DB)/$$i" | \
	    jshon -e ratings > $(OUT)/ratings/$$i.json; \
	done

# target: table - generate repeated measures/within-subjects CSV document from participant and ratings data
table:
	perl scripts/couch2csv.pl $(OUT)/{participants,ratings} > \
	$(OUT)/factors.csv

# target: delete-participants - delete participant data from couchdb server
delete-participants:
	curl -s "$(COUCHAPP_HOST)/_users/_all_docs" | \
	jshon -e rows -a -e id -u -p -e value -e rev | \
	xargs -n2 echo | \
	perl -ne 'print if m/:\w{40}/' | \
	while read id rev; do \
	    echo curl -s -XDELETE "$(COUCHAPP_HOST)/_users/$$id?rev=$$rev"; \
	done

# target: delete-ratings - delete ratings data from couchdb server
delete-ratings:
	curl -s "$(COUCHAPP_HOST)/$(COUCHAPP_DB)/_all_docs" | \
	jshon -e rows -a -e id -i -p -e value -e rev -u | \
	xargs -n2 echo | \
	while read id rev; do \
	    echo curl -s -XDELETE "$(COUCHAPP_HOST)/$(COUCHAPP_DB)/$$id?rev=$$rev" \
	done

