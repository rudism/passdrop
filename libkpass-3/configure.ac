#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.61)
AC_INIT(libkpass, 3, libkpass@bldewolf.com)
AC_CONFIG_SRCDIR([src/kpass.c])
AC_CONFIG_HEADER([src/config.h])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([-Wall -Werror])


AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_RANLIB
AC_PROG_LIBTOOL

# Checks for programs.
AC_PROG_CC

# Checks for libraries.
AC_CHECK_LIB([crypto], [EVP_MD_CTX_init], [], [AS_ECHO "Sorry, you need OpenSSL."; exit 1])

# Maybe once rlkpass is finished
#AC_CHECK_LIB([readline], [rl_get_screen_size], [
#	echo "Wonderful."
#	], [
#	echo "Sorry, you need readline."
#	exit 1
#	])

# Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([fcntl.h stdint.h stdlib.h string.h termios.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT8_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_MEMCMP
AC_FUNC_MMAP
AC_CHECK_FUNCS([memset munmap strdup getpass])

# Let's make gcc noisy
CFLAGS="$CFLAGS -Wall"

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
