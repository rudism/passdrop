#Build Notes

There are a few steps you will need to take if you want to build PassDrop yourself. I've included the libraries that allow distribution (OpenSSL and libkpass), but you will need to obtain a copy of the iOS DropBox SDK and fix the project dependency yourself.

You will need to update the DropBox application key and secret in Globals.h, as well as the key in PassDrop-Info.plist.

Some of the libraries do not compile for x64 so the project has been configured to only build 32bit binaries.
