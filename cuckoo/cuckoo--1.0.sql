/* Copyright (c) 2025 Huawei Technologies Co., Ltd.
 * SPDX-License-Identifier: MulanPSL-2.0
 */

/* contrib/cuckoo/cuckoo--1.0.sql */

-- complain if script is soured in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION cuckoo" to load this file. \quit

CREATE SCHEMA cuckoo;

----------------------------------------------------------------
-- cuckoo_control
----------------------------------------------------------------
CREATE FUNCTION pg_catalog.cuckoo_start_background_service()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_start_background_service$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_start_background_service()
    IS 'cuckoo start background service';

----------------------------------------------------------------
-- cuckoo_distributed_transaction
----------------------------------------------------------------
CREATE TABLE cuckoo.cuckoo_distributed_transaction(
    nodeid  int NOT NULL,
    gid     text NOT NULL
);
CREATE INDEX cuckoo_distributed_transaction_index
    ON cuckoo.cuckoo_distributed_transaction USING btree(nodeid);
ALTER TABLE cuckoo.cuckoo_distributed_transaction SET SCHEMA pg_catalog;
ALTER TABLE pg_catalog.cuckoo_distributed_transaction
    ADD CONSTRAINT cuckoo_distributed_transaction_unique_constraint UNIQUE (nodeid, gid);
GRANT SELECT ON pg_catalog.cuckoo_distributed_transaction TO public;

----------------------------------------------------------------
-- cuckoo_foreign_server
----------------------------------------------------------------
CREATE TABLE cuckoo.cuckoo_foreign_server(
    server_id   int NOT NULL,
    server_name text NOT NULL,
    host        text NOT NULL,
    port        int NOT NULL,
    is_local    bool NOT NULL,
    user_name   text NOT NULL
);
CREATE UNIQUE INDEX cuckoo_foreign_server_index
    ON cuckoo.cuckoo_foreign_server using btree(server_id);
ALTER TABLE cuckoo.cuckoo_foreign_server SET SCHEMA pg_catalog;
GRANT SELECT ON pg_catalog.cuckoo_foreign_server TO public;

CREATE FUNCTION pg_catalog.cuckoo_insert_foreign_server(server_id int, server_name cstring, host cstring, 
                                                 port int, is_local bool, user_name cstring)
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_insert_foreign_server$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_insert_foreign_server(server_id int, server_name cstring, host cstring, 
                                                     port int, is_local bool, user_name cstring)
    IS 'cuckoo insert foreign server';

CREATE FUNCTION pg_catalog.cuckoo_delete_foreign_server(server_id int)
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_delete_foreign_server$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_delete_foreign_server(server_id int)
    IS 'cuckoo delete foreign server';

CREATE FUNCTION pg_catalog.cuckoo_update_foreign_server(server_id int, host cstring, port int)
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_update_foreign_server$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_update_foreign_server(server_id int, host cstring, port int)
    IS 'cuckoo update foreign server';

CREATE FUNCTION pg_catalog.cuckoo_reload_foreign_server_cache()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_reload_foreign_server_cache$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_reload_foreign_server_cache()
    IS 'cuckoo reload foreign server cache';

CREATE FUNCTION pg_catalog.cuckoo_foreign_server_test(mode cstring)
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_foreign_server_test$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_foreign_server_test(mode cstring)
    IS 'cuckoo foreign server test';

----------------------------------------------------------------
-- cuckoo_shard_table
----------------------------------------------------------------
CREATE TABLE cuckoo.cuckoo_shard_table(
    range_point int NOT NULL,
    server_id   int NOT NULL
);
CREATE UNIQUE INDEX cuckoo_shard_table_index ON cuckoo.cuckoo_shard_table using btree(range_point);
ALTER TABLE cuckoo.cuckoo_shard_table SET SCHEMA pg_catalog;
GRANT SELECT ON pg_catalog.cuckoo_shard_table TO public;

CREATE FUNCTION pg_catalog.cuckoo_build_shard_table(shard_count int)
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_build_shard_table$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_build_shard_table(shard_count int)
    IS 'cuckoo build shard table';

CREATE FUNCTION pg_catalog.cuckoo_update_shard_table(range_point bigint[], server_id int[], lockInternal bool default true)
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_update_shard_table$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_update_shard_table(range_point bigint[], server_id int[], lockInternal bool)
    IS 'cuckoo update shard table';

CREATE FUNCTION pg_catalog.cuckoo_renew_shard_table()
    RETURNS TABLE(range_min int, range_max int, host text, port int, server_id int)
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_renew_shard_table$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_renew_shard_table()
    IS 'cuckoo renew shard table';

CREATE FUNCTION pg_catalog.cuckoo_reload_shard_table_cache()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_reload_shard_table_cache$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_reload_shard_table_cache()
    IS 'cuckoo reload shard table cache';

----------------------------------------------------------------
-- cuckoo_distributed_backend
----------------------------------------------------------------
CREATE FUNCTION pg_catalog.cuckoo_create_distributed_data_table()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_create_distributed_data_table$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_create_distributed_data_table()
    IS 'cuckoo create distributed data table';

CREATE FUNCTION pg_catalog.cuckoo_prepare_commands()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_prepare_commands$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_prepare_commands()
    IS 'cuckoo prepare commands';

----------------------------------------------------------------
-- cuckoo_dir_path_hash
----------------------------------------------------------------
CREATE FUNCTION pg_catalog.cuckoo_print_dir_path_hash_elem()
    RETURNS TABLE(fileName text, parentId bigint, inodeId bigint, isAcquired text)
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_print_dir_path_hash_elem$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_print_dir_path_hash_elem()
    IS 'cuckoo print dir path hash elem';

CREATE FUNCTION pg_catalog.cuckoo_acquire_hash_lock(IN path cstring, IN parentId bigint, IN lockmode bigint)
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_acquire_hash_lock$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_acquire_hash_lock(IN path cstring, IN parentId bigint, IN lockmode bigint)
    IS 'cuckoo acquire hash lock';

CREATE FUNCTION pg_catalog.cuckoo_release_hash_lock(IN path cstring, IN parentId bigint)
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_release_hash_lock$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_release_hash_lock(IN path cstring, IN parentId bigint)
    IS 'cuckoo release hash lock';

----------------------------------------------------------------
-- cuckoo_transaction_cleanup
----------------------------------------------------------------
CREATE FUNCTION pg_catalog.cuckoo_transaction_cleanup_trigger()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_transaction_cleanup_trigger$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_transaction_cleanup_trigger()
    IS 'cuckoo transaction cleanup trigger';

CREATE FUNCTION pg_catalog.cuckoo_transaction_cleanup_test()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_transaction_cleanup_test$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_transaction_cleanup_test()
    IS 'cuckoo transaction cleanup test';

----------------------------------------------------------------
-- cuckoo_directory_table
----------------------------------------------------------------]
CREATE TABLE cuckoo.cuckoo_directory_table(
    parent_id bigint,
    name text,
    inodeid bigint
);
CREATE UNIQUE INDEX cuckoo_directory_table_index ON cuckoo.cuckoo_directory_table using btree(parent_id, name);
ALTER TABLE cuckoo.cuckoo_directory_table SET SCHEMA pg_catalog;
GRANT SELECT ON pg_catalog.cuckoo_directory_table TO public;

----------------------------------------------------------------
-- cuckoo_control
----------------------------------------------------------------
CREATE FUNCTION pg_catalog.cuckoo_clear_cached_relation_oid_func()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_clear_cached_relation_oid_func$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_clear_cached_relation_oid_func()
    IS 'cuckoo clear cached relation oid func';

CREATE FUNCTION pg_catalog.cuckoo_clear_user_data_func()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_clear_user_data_func$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_clear_user_data_func()
    IS 'cuckoo clear user data';

CREATE FUNCTION pg_catalog.cuckoo_clear_all_data_func()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_clear_all_data_func$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_clear_all_data_func()
    IS 'cuckoo clear all data';

CREATE FUNCTION pg_catalog.cuckoo_run_pooler_server_func()
    RETURNS INTEGER
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_run_pooler_server_func$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_run_pooler_server_func()
    IS 'cuckoo run pooler server';


CREATE SEQUENCE cuckoo.pg_dfs_inodeid_seq
    MINVALUE 1
    INCREMENT BY 32
    MAXVALUE 9223372036854775807;
ALTER SEQUENCE cuckoo.pg_dfs_inodeid_seq SET SCHEMA pg_catalog;
CREATE TABLE cuckoo.dfs_directory_path(
    name text,
    inodeid bigint NOT NULL DEFAULT nextval('pg_dfs_inodeid_seq'),
    parentid bigint,
    subpartnum int
);
CREATE UNIQUE INDEX dfs_directory_path_index 
ON cuckoo.dfs_directory_path using btree(parentid, name);
ALTER TABLE cuckoo.dfs_directory_path SET SCHEMA pg_catalog;
-- end add--

----------------------------------------------------------------
-- cuckoo_plain_interface
----------------------------------------------------------------
CREATE FUNCTION pg_catalog.cuckoo_plain_mkdir(path cstring)
    RETURNS int
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_plain_mkdir$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_plain_mkdir(path cstring) IS 'cuckoo plain mkdir';

CREATE FUNCTION pg_catalog.cuckoo_plain_create(path cstring)
    RETURNS int
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_plain_create$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_plain_create(path cstring) IS 'cuckoo plain create';

CREATE FUNCTION pg_catalog.cuckoo_plain_stat(path cstring)
    RETURNS int
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_plain_stat$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_plain_stat(path cstring) IS 'cuckoo plain stat';

CREATE FUNCTION pg_catalog.cuckoo_plain_rmdir(path cstring)
    RETURNS int
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_plain_rmdir$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_plain_rmdir(path cstring) IS 'cuckoo plain rmdir';

CREATE FUNCTION pg_catalog.cuckoo_plain_readdir(path cstring)
    RETURNS text
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_plain_readdir$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_plain_readdir(path cstring) IS 'cuckoo plain readdir';


----------------------------------------------------------------
-- cuckoo_serialize_interface
----------------------------------------------------------------
CREATE FUNCTION pg_catalog.cuckoo_meta_call_by_serialized_shmem_internal(type int, count int, shmem_shift bigint, signature bigint)
    RETURNS bigint
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_meta_call_by_serialized_shmem_internal$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_meta_call_by_serialized_shmem_internal(type int, count int, shmem_shift bigint, signature bigint) IS 'cuckoo meta func by serialized shmem internal';

CREATE FUNCTION pg_catalog.cuckoo_meta_call_by_serialized_data(type int, count int, param bytea)
    RETURNS bytea
    LANGUAGE C STRICT
    AS 'MODULE_PATHNAME', $$cuckoo_meta_call_by_serialized_data$$;
COMMENT ON FUNCTION pg_catalog.cuckoo_meta_call_by_serialized_data(type int, count int, param bytea) IS 'cuckoo meta call by serialized data';