INSTALL_NAME = ironbank
INSTALL_PATH = /usr/local/bin

all : build
.PHONY : all build install uninstall clean

build : clean
	@swift build -c release -Xswiftc -static-stdlib

install : build
	@cp .build/release/IronBank $(INSTALL_PATH)/$(INSTALL_NAME)
	@echo "\033[0;32m\nIronBank is installed in '$(INSTALL_PATH)/$(INSTALL_NAME)'"

uninstall :
	@rm $(INSTALL_PATH)/$(INSTALL_NAME)

clean :
	@swift package clean