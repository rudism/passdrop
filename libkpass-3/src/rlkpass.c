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
#include <readline/readline.h>
#include <readline/history.h>
#include <unistd.h>

#include "kpass.h"

static kpass_db *db = NULL;
//static char **db_name = NULL;
//static int db_len = 0;

static uint8_t *pw_hash = NULL;
//static int pw_len = 0;

int load_file(char *filename) {
	int fd;
	struct stat sb;
	int length;
	int retval = 0;
	uint8_t *file;

	fd = open(filename, O_RDONLY);
	if(fd == -1)
		return -1;

	if(fstat(fd, &sb) == -1) {
		close(fd);
		return -2;
	}

	db = malloc(sizeof(kpass_db));

	length = sb.st_size;

	file = mmap(NULL, length, PROT_READ, MAP_SHARED, fd, 0);
	if(file == MAP_FAILED) {
		close(fd);
		return -3;
	}
	
	retval = kpass_init_db(db, file, length);

	munmap(file, length);
	close(fd);

	return retval;
}

int hash_pw(char *pw) {
	return kpass_hash_pw(db, pw, pw_hash);
}

int decrypt_db(void) {
	return kpass_decrypt_db(db, pw_hash);
}

int save_file(char *filename) {
//	int fd;
//	struct stat sb;
//	int length;
//	int retval = 0;
	uint8_t *file = NULL;

	/* do stuff to setup the file */

	kpass_encrypt_db(db, pw_hash, file);

	return 0;
}

int main(int argc, char* argv[]) {
//	kpass_retval retval;

	rl_initialize();


	return 0;
}

