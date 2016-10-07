######################################################################

CC?=gcc

RELEASE_DIR?=bin
IDIR:=inc
ODIR:=obj
SDIR:=src
DDIR:=dep
ALL_DIRS=$(RELEASE_DIR) $(IDIR) $(SDIR) $(DDIR) $(ODIR)
TEMP_DIRS=$(RELEASE_DIR) $(DDIR) $(ODIR)

# vpath directives
# Headers
vpath %.h $(SDIR)
vpath %   $(IDIR)
# Source
vpath %.c $(SDIR)
# Objects
vpath %.o $(ODIR)
# Depends
vpath %.d $(DDIR)

LIBS+=gstreamer-1.0 gstreamer-rtsp-server-1.0 glib-2.0

LDFLAGS+=$(shell pkg-config --libs $(LIBS))
ALL_LDFLAGS=$(LDFLAGS)
CFLAGS+=-Wall
CFLAGS+=$(shell pkg-config --cflags $(LIBS))
ALL_CFLAGS=-I$(IDIR) $(CFLAGS)
ALLFLAGS=$(ALL_CFLAGS) $(ALL_LDFLAGS)

COMPILE.c=$(CC) $(ALL_CFLAGS) -c -o $@ $<
LINK.o=$(CC) $(ALL_CFLAGS) $^ $(ALL_LDFLAGS) -o $(RELEASE_DIR)/$@

SRCS=$(wildcard $(SDIR)/*.c)
HDRS=$(wildcard $(SDIR)/*.h)
OBJS=$(patsubst $(SDIR)/%.c,$(ODIR)/%.o,$(SRCS))
DEPS=$(patsubst $(SDIR)/%.c,$(DDIR)/%.d,$(SRCS))
SRCFILES=$(SRCS) $(HDRS)

GST_SERVER_LIBS=
GST_SERVER_OBJS=$(ODIR)/gst-server.o

APPS:=gst-server

all: $(APPS)

## Creates src.d per source file
# 1st sed cmd moves :
# 2nd sed cmd adds $(ODIR) before the object
$(DDIR)/%.d: %.c
	@mkdir -p $(@D)

ifdef V
	@echo Generating $(@F)
endif
	@set -e; rm -f $@; \
	$(CC) $(ALL_CFLAGS) -MM $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ | \
	sed 's,$*.o,$(ODIR)/$*.o,g' > $@; \
	rm -f $@.$$$$

# create object files
define create-obj
	@mkdir -p $(@D)

	$(if $V,@echo "--------------------- $1 ------------------------",
		@echo Compiling $<)
	$(if $V,$(COMPILE.c),@$(COMPILE.c))
	$(if $V,@echo "-------------------- $1 end ----------------------")
endef

$(ODIR)/%.o: %.c
	$(call create-obj,$(@F))

# Only call from within the context of linking
define dbg-link
	@mkdir -p $(RELEASE_DIR)

	$(if $V,@echo "--------------------- $1 ------------------------",
		@echo Linking $^)
	$(if $V,$(LINK.o) $2,@$(LINK.o) $2)
	$(if $V,@echo "-------------------- $1 end ----------------------")
	@echo Binary $(RELEASE_DIR)/$1
	@echo
endef

# Add App Targets here
gst-server: $(GST_SERVER_OBJS)
	$(call dbg-link,"gst-server")

.PHONY: clean
clean:
ifdef V
	@echo Cleaning files: $(wildcard $(ODIR)/*) \
			      $(wildcard $(DDIR)/*) \
			      $(wildcard $(RELEASE_DIR)/*)
endif
	@rm -rfv $(ODIR) $(DDIR) $(RELEASE_DIR)

	@exit 0

# Source New Makefiles.. generation occurs when required
-include $(DEPS)

######################################################################
