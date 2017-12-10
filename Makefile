CommandName = ironbank
InstallPath = /usr/local/bin

all : build
.PHONY : all build install uninstall clean

build : clean
	@swift build -c release -Xswiftc -static-stdlib

install : build
	@cp .build/release/IronBank $(InstallPath)/$(CommandName)
	@echo "\033[0;32m\nIronBank is installed in '$(InstallPath)/$(CommandName)'"

uninstall :
	@rm $(InstallPath)/$(CommandName)

clean :
	@swift package clean