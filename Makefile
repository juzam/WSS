# general setup
COMMON_CXX_FLAGS = -Wall -fstack-protector

ifeq ($(DEBUG), 1)
	BIN_NAME = WSS_debug
	WORK_DIR = build_debug
	CXX_FLAGS = $(COMMON_CXX_FLAGS) -ggdb -DDEBUG
else
	BIN_NAME = WSS
	WORK_DIR = build_release
	CXX_FLAGS = $(COMMON_CXX_FLAGS) -Wall -O3
endif

# boost
BOOST_PREFIX ?= /usr/local
BOOST_LIB_PATH		?= $(BOOST_PREFIX)/lib
BOOST_INCLUDE_PATH  ?= $(BOOST_PREFIX)/include

BOOST_LIBS = boost_program_options boost_system boost_thread boost_date_time boost_regex

ifeq ($(wildcard $(BOOST_LIB_PATH)/libboost*-mt.a),)
	BOOST_STATIC_LIBS := $(foreach LIB, $(BOOST_LIBS), $(BOOST_LIB_PATH)/lib$(LIB).a)
else
	BOOST_STATIC_LIBS := $(foreach LIB, $(BOOST_LIBS), $(BOOST_LIB_PATH)/lib$(LIB)-mt.a)
endif

BOOST_DYNAMIC_LIBS := -L$(BOOST_LIB_PATH) $(foreach LIB, $(BOOST_LIBS), -l$(LIB))


# shared or static
ifeq ($(SHARED), 1)
	BIN_NAME := $(BIN_NAME)_shared
	LINKER_SETTINGS = -Lwebsocketpp -lwebsocketpp $(BOOST_DYNAMIC_LIBS) -ldl -lrt -lpthread
else
	LINKER_SETTINGS = websocketpp/libwebsocketpp.a $(BOOST_STATIC_LIBS) -ldl -lrt -lpthread -static
endif


INCLUDES = -I$(BOOST_INCLUDE_PATH) -Isrc -Iwebsocketpp/src


all: websocketpp $(BIN_NAME)

gitSubmodules:
	git submodule init 
	git submodule update
	
websocketpp: gitSubmodules
	cd websocketpp; \
	make; \
	make SHARED=1

$(BIN_NAME): $(WORK_DIR)/WSS.o
	g++ -o $(BIN_NAME) $(WORK_DIR)/WSS.o $(LINKER_SETTINGS)

$(WORK_DIR)/WSS.o: src/WSS.cpp
	g++ -c -o $(WORK_DIR)/WSS.o $(INCLUDES) src/WSS.cpp $(CXX_FLAGS)
	
clean: clean_debug clean_release clean_websocketpp

clean_debug:
	rm -f WSS_debug WSS_debug_static
	rm -f build_debug/*

clean_release:
	rm -f WSS WSS_static
	rm -f build_release/*

clean_websocketpp:
	cd websocketpp; \
	make clean