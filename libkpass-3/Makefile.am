TESTS=test1
#bin_PROGRAMS = rlkpass
check_PROGRAMS = test1 test2
lib_LTLIBRARIES = libkpass.la
libkpass_la_SOURCES = src/kpass.c
include_HEADERS = src/kpass.h
test1_SOURCES  = src/test1.c
test1_LDADD = libkpass.la
test2_SOURCES  = src/test2.c
test2_LDADD = libkpass.la
#rlkpass_SOURCES = src/rlkpass.c
#rlkpass_LDADD = -lreadline libkpass.la

EXTRA_DIST = DbFormat.txt TODO src/rlkpass.c

EXTRA_DIST += test/block0.kdb test/block1.kdb test/block2.kdb test/block3.kdb test/block4.kdb test/block5.kdb test/block6.kdb test/block7.kdb test/block8.kdb test/block9.kdb test/block10.kdb test/block11.kdb test/block12.kdb test/block13.kdb test/block14.kdb test/block15.kdb
