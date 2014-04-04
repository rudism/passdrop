/*
    libkpass, a library for reading and writing KeePass format files
    Copyright (C) 2009 Brian De Wolf

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <sys/mman.h>
#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>

#include "kpass.h"

char *totest[16] = { "test/block0.kdb",
		"test/block1.kdb",
		"test/block2.kdb",
		"test/block3.kdb",
		"test/block4.kdb",
		"test/block5.kdb",
		"test/block6.kdb",
		"test/block7.kdb",
		"test/block8.kdb",
		"test/block9.kdb",
		"test/block10.kdb",
		"test/block11.kdb",
		"test/block12.kdb",
		"test/block13.kdb",
		"test/block14.kdb",
		"test/block15.kdb" };


/* This function opens a file, decrypts it, and re-encrypts it and compares it to the original */

int testfile(char *filename, char *pass) {
	uint8_t *file = NULL;
	int length;
	int fd;
	struct stat sb;
	unsigned char pw_hash[32];
	kpass_db *db;
	kpass_retval retval;
	uint8_t *outdb;
	int outdb_len;

	db = malloc(sizeof(kpass_db));

	fd = open(filename, O_RDONLY);
	if(fd == -1) {
		printf("open failed: %m\n");
		return -1;
	}

	if(fstat(fd, &sb) == -1) {
		printf("fstat failed: %m\n");
		return -1;
	}

	length = sb.st_size;

	file = mmap(NULL, length, PROT_READ, MAP_SHARED, fd, 0);
	if(file == MAP_FAILED) {
		printf("mmap failed: %m\n");
		return -1;
	}
	retval = kpass_init_db(db, file, length);
	printf("init: %s\n", kpass_error_str[retval]);
	if(retval) {
		munmap(file, length);
		free(db);
		return retval;
	}

	retval = kpass_hash_pw(db, pass, pw_hash);
	printf("hash: %s\n", kpass_error_str[retval]);
	if(retval) {
		munmap(file, length);
		kpass_free_db(db);
		free(db);
		return retval;
	}
	
	retval = kpass_decrypt_db(db, pw_hash);
	printf("decrypt: %s\n", kpass_error_str[retval]);
	if(retval) {
		munmap(file, length);
		kpass_free_db(db);
		free(db);
		return retval;
	}

	outdb_len = kpass_db_encrypted_len(db);
	outdb = malloc(outdb_len);

	retval = kpass_encrypt_db(db, pw_hash, outdb);
	printf("encrypt: %s\n", kpass_error_str[retval]);
	if(retval) {
		munmap(file, length);
		kpass_free_db(db);
		free(db);
		free(outdb);
		return retval;
	}

	retval = memcmp(file, outdb, outdb_len);
	printf("comparison: %d\n", retval);

	munmap(file, length);

	kpass_free_db(db);

	free(db);
	free(outdb);

	return retval;
}

int main(int argc, char* argv[]) {
	int i;
	char *pass = "test";
	int retval;

	for(i = 0; i < 16; i++) {
		printf("On file %s:\n", totest[i]);
		retval = testfile(totest[i], pass);
		if(retval) return retval;
	}
	return 0;
}
