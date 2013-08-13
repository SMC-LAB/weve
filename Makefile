FFMPEG        = $(shell which ffmpeg)
CURL          = $(shell which curl)
JSHON         = $(shell which jshon)
COUCHAPP      = $(shell which couchapp)
PERL          = $(shell which perl)
FS2JSON       = scripts/fs2json.pl
JSON2COUCH    = scripts/json2couch.pl
COUCH2CSV     = scripts/couch2csv.pl
OUT_DIR       = out
AUDIO_DIR     = in
AUDIO_EXT     = wav
COUCHAPP_ENV  = default
COUCHAPP_RC   = .couchapprc
COUCHAPP_HOST := $(shell jshon -e env -e $(COUCHAPP_ENV) -e db < $(COUCHAPP_RC) -u | cut -d'/' -f 1,2,3)
COUCHAPP_DB   := $(shell jshon -e env -e $(COUCHAPP_ENV) -e db < $(COUCHAPP_RC) -u | cut -d'/' -f 4)
MP3_FILES     := $(patsubst $(AUDIO_DIR)/%, $(OUT_DIR)/audio/%, $(patsubst %.$(AUDIO_EXT), %.mp3, $(wildcard $(AUDIO_DIR)/*$(AUDIO_EXT))))
M4A_FILES     := $(patsubst $(AUDIO_DIR)/%, $(OUT_DIR)/audio/%, $(patsubst %.$(AUDIO_EXT), %.m4a, $(wildcard $(AUDIO_DIR)/*$(AUDIO_EXT))))
OGA_FILES     := $(patsubst $(AUDIO_DIR)/%, $(OUT_DIR)/audio/%, $(patsubst %.$(AUDIO_EXT), %.oga, $(wildcard $(AUDIO_DIR)/*$(AUDIO_EXT))))

all: help

# target: help - print this information
help: usage targets variables

# target: usage - print usage information
usage:
	@echo "Usage:"
	@echo "    make experiment AUDIO_DIR=/some/audio/files/dir OUT_DIR=/some/output/dir # upload experiment"
	@echo "    make analyze OUT_DIR=/some/output/dir                                    # download data"
	@echo "    make clean OUT_DIR=/some/output/dir                                      # delete local data"
	@echo "    make cleanup                                                             # delete remote data"

# target: targets - print available targets
targets:
	@echo "Targets:"
	@egrep "^# target: [^ ]+" [Mm]akefile | sed 's/# target: /    /'

# target: variables - print available variables
variables:
	@echo "Variables:"
	@echo "    FFMPEG=$(FFMPEG)"
	@echo "    PERL=$(PERL)"
	@echo "    COUCHAPP=$(COUCHAPP)"
	@echo "    FS2JSON=$(FS2JSON)"
	@echo "    JSON2COUCH=$(JSON2COUCH)"
	@echo "    COUCH2CSV=$(COUCH2CSV)"
	@echo "    OUT_DIR=$(OUT_DIR)"
	@echo "    AUDIO_DIR=$(AUDIO_DIR)"
	@echo "    AUDIO_EXT=$(AUDIO_EXT)"
	@echo "    COUCHAPP_ENV=$(COUCHAPP_ENV)"
	@echo "    COUCHAPP_RC=$(COUCHAPP_RC)"
	@echo "    COUCHAPP_HOST=$(COUCHAPP_HOST)"
	@echo "    COUCHAPP_DB=$(COUCHAPP_DB)"

# target: experiment - prepare local filesystem, generate and upload design document
experiment: dir convert design deploy upload

# target: analyze - dump participants and ratings as a repeated measures/within-subjects `csv` document
analyze: participants ratings table

# target: cleanup - delete participant and ratings data from the server
cleanup: delete-participants delete-ratings

# target: clean - delete local output directory
clean:
	rm -rf $(OUT_DIR)

# target: check - ensure all dependencies are met
check: $(FFMPEG) $(COUCHAPP) $(PERL) $(FS2JSON) $(JSON2COUCH) $(COUCH2CSV)
	@$(PERL) -c $(FS2JSON)
	@$(PERL) -c $(JSON2COUCH)
	@$(PERL) -c $(COUCH2CSV)

# target: dir - create local experiment filesystem
dir:
	mkdir -p $(OUT_DIR)/{audio,participants,ratings}

# target: convert - convert audio files `$AUDIO_DIR/*.$AUDIO_EXT` to `mp3`, `m4a`, and `oga`
convert: $(MP3_FILES) $(M4A_FILES) $(OGA_FILES)

$(MP3_FILES): $(OUT_DIR)/audio/%.mp3: $(AUDIO_DIR)/%.$(AUDIO_EXT)
	$(FFMPEG) -loglevel quiet -i $< -acodec libmp3lame -ab 192K -ar 44100 $@

$(M4A_FILES): $(OUT_DIR)/audio/%.m4a: $(AUDIO_DIR)/%.$(AUDIO_EXT)
	$(FFMPEG) -loglevel quiet -i $< -strict experimental -c:a aac -cutoff 15000 -b:a 192k $@

$(OGA_FILES): $(OUT_DIR)/audio/%.oga: $(AUDIO_DIR)/%.$(AUDIO_EXT)
	$(FFMPEG) -loglevel quiet -i $< -acodec libvorbis -f ogg -aq 6 -ar 44100 $@

# target: design - generate `couchdb` design document from local filesystem
design:
	$(PERL) scripts/fs2json.pl -a audio=$(OUT_DIR)/audio -o $(OUT_DIR)/design.json

# target: deploy - upload the `weve` design document to the server
deploy:
	couchapp push $(COUCHAPP_ENV)

# target: upload - upload audio files as attachments to the server
upload:
	$(PERL) scripts/json2couch.pl -i $(OUT_DIR)/design.json -u $(COUCHAPP_HOST) -d $(COUCHAPP_DB) -a

# target: participants - dump series of participant data as `json` documents
participants:
	$(CURL) -s "$(COUCHAPP_HOST)/_users/_all_docs" | \
	$(JSHON) -e rows -a -e id | \
	sed 's/"//g' | \
	$(PERL) -ne 'print if m/:\w{40}/' | \
	while read i; do \
	    $(CURL) -s "$(COUCHAPP_HOST)/_users/$$i" > \
	    $(OUT_DIR)/participants/$$i.json; \
	done

# target: ratings - dump series of ratings data as `json` documents
ratings:
	$(CURL) -s "$(COUCHAPP_HOST)/$(COUCHAPP_DB)/_all_docs" | \
	$(JSHON) -e rows -a -e id | \
	$(PERL) -ne 's/"//g; print unless m/^_/' | \
	while read i; do \
	    $(CURL) -s "$(COUCHAPP_HOST)/$(COUCHAPP_DB)/$$i" | \
	    $(JSHON) -e ratings > $(OUT_DIR)/ratings/$$i.json; \
	done

# target: table - generate repeated measures/within-subjects `csv` document from participant and ratings data
table:
	$(PERL) scripts/couch2csv.pl $(OUT_DIR)/{participants,ratings} > \
	$(OUT_DIR)/factors.csv

# target: delete-participants - delete participant data from `couchdb` server
delete-participants:
	$(CURL) -s "$(COUCHAPP_HOST)/_users/_all_docs" | \
	$(JSHON) -e rows -a -e id -u -p -e value -e rev | \
	xargs -n2 echo | \
	$(PERL) -ne 'print if m/:\w{40}/' | \
	while read id rev; do \
	    echo $(CURL) -s -XDELETE "$(COUCHAPP_HOST)/_users/$$id?rev=$$rev"; \
	done

# target: delete-ratings - delete ratings data from `couchdb` server
delete-ratings:
	$(CURL) -s "$(COUCHAPP_HOST)/$(COUCHAPP_DB)/_all_docs" | \
	$(JSHON) -e rows -a -e id -i -p -e value -e rev -u | \
	xargs -n2 echo | \
	while read id rev; do \
	    echo $(CURL) -s -XDELETE "$(COUCHAPP_HOST)/$(COUCHAPP_DB)/$$id?rev=$$rev" \
	done

.phony: all                 \
	help		    \
	usage		    \
	targets		    \
	variables	    \
	experiment	    \
	analyze		    \
	cleanup		    \
	clean		    \
	check		    \
	dir		    \
	convert		    \
	design		    \
	deploy		    \
	upload		    \
	participants	    \
	ratings		    \
	table		    \
	delete-participants \
	delete-ratings
