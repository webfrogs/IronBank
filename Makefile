CommandName = ironbank
InstallPath = /usr/local/bin/

all : build install uninstall
.PHONY : all build install uninstall

build :
	@swift build -c release -Xswiftc -static-stdlib

install : build
	@cp .build/release/IronBank $(InstallPath)/$(CommandName)

uninstall :
	@rm $(InstallPath)/$(CommandName)

