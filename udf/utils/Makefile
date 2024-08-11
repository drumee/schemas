# Makefile for MariaDB UDFs

# Set the name of your library
LIBRARY=drumee

# Set the path to your MariaDB installation
MARIADB_PATH=/usr/local/mariadb

# Set the path to your plugin directory
PLUGIN_DIR=$(MARIADB_PATH)/lib/plugin

# Set the compiler and flags
INCLUDE_FLAGS=`mysql_config --cflags`
CC=gcc
CFLAGS=-DMYSQL_DYNAMIC_PLUGIN -Wall -fPIC -I/usr/include/mariadb -I/usr/include/mariadb/mysql -I/usr/include/mysql

# Set the linker and flags
LIBS_FLAG=-L/usr/lib/x86_64-linux-gnu/ -lmariadb
LD=gcc
LDFLAGS=-shared -L/usr/lib/x86_64-linux-gnu/ -lmariadb


# Set the source files for your library
SOURCES=pageToLimits.c

# Set the object files for your library
OBJECTS=$(SOURCES:.c=.o)

# Set the name of the output file
OUTPUT=$(LIBRARY).so

all: $(OUTPUT)

$(OUTPUT): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(OUTPUT)

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@

install: $(OUTPUT)
	cp $(OUTPUT) $(PLUGIN_DIR)

uninstall:
	rm $(PLUGIN_DIR)/$(OUTPUT)

clean:
	rm -f $(OBJECTS) $(OUTPUT)

test:
	@echo $(INCLUDE)