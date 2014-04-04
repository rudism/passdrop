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


#ifndef __KPASS_H__
#define __KPASS_H__

#include <stdint.h>
#include <time.h>

/*
 *
 *
 * Defining structures and other constants
 *
 *
 */

typedef struct kpass_db kpass_db;
typedef struct kpass_entry kpass_entry;
typedef struct kpass_group kpass_group;

typedef enum kpass_group_type kpass_group_type;
typedef enum kpass_entry_type kpass_entry_type;
typedef enum kpass_retval kpass_retval;

enum kpass_retval {
	kpass_success,
	kpass_decrypt_data_fail,
	kpass_decrypt_db_fail,
	kpass_hash_pw_fail,
	kpass_prepare_key_fail,
	kpass_load_decrypted_data_entry_fail,
	kpass_load_decrypted_data_group_fail,
	kpass_init_db_fail,
	kpass_encrypt_db_fail,
	kpass_encrypt_data_fail,
	kpass_pack_db_fail,
	kpass_verification_fail,
	kpass_unsupported_flag,
	kpass_not_implemented,
};
#define kpass_retval_len 14

extern char *kpass_error_str_en_US[];
extern char **kpass_error_str;

/*
int kpass_header_len = 124;
*/
#define kpass_header_len 124

struct kpass_db {
	/* These are in the order they appear in the header */
	/* signature */
	uint32_t flags;
	uint32_t version;
	uint8_t  master_seed[16]; /* FinalKey = SHA-256(aMasterSeed, TransformedUserMasterKey) */
	uint8_t  encryption_init_vector[16]; /* Init vector for AES/Twofish */
	uint32_t groups_len;
	uint32_t entries_len;
	uint8_t  contents_hash[32]; /* Hash of decrypted data */
	uint8_t  master_seed_extra[32]; /* Used for extra AES transformations */
	uint32_t key_rounds;

	kpass_group **groups;
	kpass_entry **entries;
	uint8_t *encrypted_data; /* Encrypted data, before decrypt/after encrypt */
	int encrypted_data_len;
};

/* Maps for flags */
#define kpass_flag_SHA2 1
#define kpass_flag_RIJNDAEL 2
#define kpass_flag_ARCFOUR 4
#define kpass_flag_TWOFISH 8
#define kpass_flag_INVALID 16


struct kpass_group {
	uint32_t id, image_id;
	char *name;
	uint8_t ctime[5], mtime[5], atime[5], etime[5];
	uint16_t level;
	uint32_t flags;
};

/*
 * Possible group field types:
 */
enum kpass_group_type {
	kpass_group_comment,   /* 0000: Invalid or comment block, block is ignored */
	kpass_group_id,        /* 0001: Group ID, FIELDSIZE must be 4 bytes
			        * It can be any 32-bit value except 0 and 0xFFFFFFFF */
	kpass_group_name,      /* 0002: Group name, FIELDDATA is an UTF-8 encoded string */
	kpass_group_ctime,     /* 0003: Creation time, FIELDSIZE = 5, FIELDDATA = packed date/time */
	kpass_group_mtime,     /* 0004: Last modification time, FIELDSIZE = 5, FIELDDATA = packed date/time */
	kpass_group_atime,     /* 0005: Last access time, FIELDSIZE = 5, FIELDDATA = packed date/time */
	kpass_group_etime,     /* 0006: Expiration time, FIELDSIZE = 5, FIELDDATA = packed date/time */
	kpass_group_image_id,  /* 0007: Image ID, FIELDSIZE must be 4 bytes */
	kpass_group_level,     /* 0008: Level, FIELDSIZE = 2 */
	kpass_group_flags,     /* 0009: Flags, 32-bit value, FIELDSIZE = 4 */
	kpass_group_num_types, /* If type is this or greater and not 0xFFFF, error */
	kpass_group_term = 0xFFFF /* FFFF: Group entry terminator, FIELDSIZE must be 0 */
};


struct kpass_entry {
	uint8_t uuid[16];
	uint32_t group_id;
	uint32_t image_id;
	char *title, *url, *username, *password, *notes, *desc;
	uint8_t ctime[5], mtime[5], atime[5], etime[5];
	uint32_t data_len;
	uint8_t *data;
};

/*
 * Possible entry field types:
 */
enum kpass_entry_type {
	kpass_entry_comment,   /* 0000: Invalid or comment block, block is ignored */
	kpass_entry_uuid,      /* 0001: UUID, uniquely identifying an entry, FIELDSIZE must be 16 */
	kpass_entry_group_id,  /* 0002: Group ID, identifying the group of the entry, FIELDSIZE = 4
	                        * It can be any 32-bit value except 0 and 0xFFFFFFFF */
	kpass_entry_image_id,  /* 0003: Image ID, identifying the image/icon of the entry, FIELDSIZE = 4 */
	kpass_entry_title,     /* 0004: Title of the entry, FIELDDATA is an UTF-8 encoded string */
	kpass_entry_url,       /* 0005: URL string, FIELDDATA is an UTF-8 encoded string */
	kpass_entry_username,  /* 0006: UserName string, FIELDDATA is an UTF-8 encoded string */
	kpass_entry_password,  /* 0007: Password string, FIELDDATA is an UTF-8 encoded string */
	kpass_entry_notes,     /* 0008: Notes string, FIELDDATA is an UTF-8 encoded string */
	kpass_entry_ctime,     /* 0009: Creation time, FIELDSIZE = 5, FIELDDATA = packed date/time */
	kpass_entry_mtime,     /* 000A: Last modification time, FIELDSIZE = 5, FIELDDATA = packed date/time */
	kpass_entry_atime,     /* 000B: Last access time, FIELDSIZE = 5, FIELDDATA = packed date/time */
	kpass_entry_etime,     /* 000C: Expiration time, FIELDSIZE = 5, FIELDDATA = packed date/time */
	kpass_entry_desc,      /* 000D: Binary description UTF-8 encoded string */
	kpass_entry_data,      /* 000E: Binary data */
	kpass_entry_num_types, /* If type is this or greater and not 0xFFFF, error */
	kpass_entry_term = 0xFFFF /* FFFF: Entry terminator, FIELDSIZE must be 0 */
};

/*
 *
 *
 * Functions
 *
 *
 */

/*
 * empty->encrypted functions */

/* kpass_init_db - Loads header and encrypted block into data structure.
 * db: Allocated but untouched kpass_db
 * data: Password database data (entire file)
 * len: length of data
 *
 * This function loads the header and copies the encrypted portion into the
 * data structure.  The original copy is no longer needed after this is called.
 * This is necessary before hashing can occur as hashing uses data from the
 * headers.
 */
kpass_retval	kpass_init_db(kpass_db *db, const uint8_t *data, const int len);


/*
 * shared crypto functions */

/* kpass_hash_pw - Generate hash (for crypting) from a string.
 * db: kpass_db that has been loaded
 * pw: string to be hashed
 * pw_hash: 32-byte pre-allocated location for the hash to be returned in
 *
 * Use this function to hash the password for use with encryption and
 * decryption.   However, it only performs the first step as to provide an
 * alternative to storing the plaintext password while maintaining the ability
 * to produce a database key with different parameters (seeds, key rounds, init
 * vectors).
 */
kpass_retval	kpass_hash_pw(const kpass_db *db, const char *pw, uint8_t *pw_hash);


/*
 * encrypted->decrypted functions */

/* kpass_decrypt_db - Decrypt database db using hash pw_hash
 * db: database to be decrypted (should not have been decrypted already)
 * pw_hash:  hash to decrypt with
 *
 * Use this function to decrypt the database and load it into the groups and
 * entries structures in the database.  This also frees the encrypted block
 * from the original database initialization, so don't try to decrypt twice.
 */
kpass_retval	kpass_decrypt_db(kpass_db *db, const uint8_t *pw_hash);


/* 
 * encrypting functions */

/* kpass_encrypt_db - Encrypt database db using hash pw_hash onto buffer buf
 * db: database to be encrypted (in a decrypted state, as in groups and entries present)
 * pw_hash: hash to encrypt with
 * buf: a buffer large enough to hold the encrypted database (use kpass_db_encrypted_len)
 *
 * Use this function to write the database as it would appear on disk in the
 * buffer.  The buffer is not allocated or managed by the library (one might
 * consider using mmapped space for writing the database to a file).  This
 * function modifies db by updating the hash with the hash of the packed
 * database.  It does not free any of the entry or group structures (the
 * database can be encrypted multiple times).
 */
kpass_retval	kpass_encrypt_db(kpass_db *db, const uint8_t *pw_hash, uint8_t * buf);

/* kpass_db_encrypted_len - Returns the length of the database after
 * encryption.  Use to calculate the size of the buffer to hold the encrypted
 * database.
 */
int		kpass_db_encrypted_len(const kpass_db *db);

/* UNIMPLEMENTED */
kpass_retval	kpass_insert_group(kpass_db *db, kpass_group *group);

/*
 * packed time functions */

/* kpass_unpack_time - Unpack the 5 byte packed time format into struct tm tms
 * time: 5 byte array from which to unpack the time
 * tms: tm structure in which to place the time
 *
 * Note that 2999-12-28 23:59:59 is considered to be "Never" for expiration time.
 */
void kpass_unpack_time(const uint8_t time[5], struct tm *tms);

/* kpass_pack_time - Pack the struct tm tms into the 5 byte packed format
 * tms: tm structure from which to get the time
 * time: 5 byte array in which to pack the time
 *
 * Note that 2999-12-28 23:59:59 is considered to be "Never" for expiration time.
 */
void kpass_pack_time(const struct tm *tms, uint8_t time[5]);

/* These functions free the internal structures of the kpass database.  Use
 * kpass_free_db before freeing the struct or initing a new database */
void	kpass_free_db(kpass_db *db);
void	kpass_free_group(kpass_group *group);
void	kpass_free_groups(kpass_db *db);
void	kpass_free_entry(kpass_entry *entry);
void	kpass_free_entries(kpass_db *db);

#endif
