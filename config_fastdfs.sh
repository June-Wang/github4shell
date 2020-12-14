#!/bin/bash

path="$1"

test -z "${path}"||\
eval "echo Usage: /bin/bash config_fastdfs.sh [data_path];exit 1"

echo "${path}"|grep -E '^/' >/dev/null 2>&1 ||\
eval "echo ${path} is not valid!;exit 1"

test -d ${path} ||\
mkdir -p ${path}

test -d ${path}/tracker ||\
mkdir -p ${path}/tracker

test -d ${path}/storage ||\
mkdir -p ${path}/storage

mkdir -p ${path}/fdfs_client/logs  #日志存放路径

cat >/etc/fdfs/client.conf <<EOF
connect_timeout = 5
network_timeout = 60
base_path = ${path}/fdfs_client/logs
tracker_server = 192.168.31.101:22122
tracker_server = 192.168.31.102:22122
log_level = info
use_connection_pool = false
connection_pool_max_idle_time = 3600
load_fdfs_parameters_from_tracker = false
use_storage_id = false
storage_ids_filename = storage_ids.conf
http.tracker_server_port = 18080
EOF

cat >/etc/fdfs/tracker.conf <<EOF
disabled = false
bind_addr =
port = 22122
connect_timeout = 5
network_timeout = 60
base_path = ${path}/tracker
max_connections = 1024
accept_threads = 1
work_threads = 4
min_buff_size = 8KB
max_buff_size = 128KB
store_lookup = 0
store_server = 0
store_path = 0
download_server = 0
reserved_storage_space = 20%
log_level = info
run_by_group=
run_by_user =
allow_hosts = *
sync_log_buff_interval = 1
check_active_interval = 120
thread_stack_size = 256KB
storage_ip_changed_auto_adjust = true
storage_sync_file_max_delay = 86400
storage_sync_file_max_time = 300
use_trunk_file = false
slot_min_size = 256
slot_max_size = 1MB
trunk_alloc_alignment_size = 256
trunk_free_space_merge = true
delete_unused_trunk_files = false
trunk_file_size = 64MB
trunk_create_file_advance = false
trunk_create_file_time_base = 02:00
trunk_create_file_interval = 86400
trunk_create_file_space_threshold = 20G
trunk_init_check_occupying = false
trunk_init_reload_from_binlog = false
trunk_compress_binlog_min_interval = 86400
trunk_compress_binlog_interval = 86400
trunk_compress_binlog_time_base = 03:00
trunk_binlog_max_backups = 7
use_storage_id = false
storage_ids_filename = storage_ids.conf
id_type_in_filename = id
store_slave_file_use_link = false
rotate_error_log = false
error_log_rotate_time = 00:00
compress_old_error_log = false
compress_error_log_days_before = 7
rotate_error_log_size = 0
log_file_keep_days = 0
use_connection_pool = true
connection_pool_max_idle_time = 3600
http.server_port = 8080
http.check_alive_interval = 30
http.check_alive_type = tcp
http.check_alive_uri = /status.html
EOF

cat >/etc/fdfs/storage.conf<<EOF
disabled = false
group_name = group1
bind_addr =
client_bind = true
port = 23000
connect_timeout = 5
network_timeout = 60
heart_beat_interval = 30
stat_report_interval = 60
base_path = ${path}/storage
max_connections = 1024
buff_size = 256KB
accept_threads = 1
work_threads = 4
disk_rw_separated = true
disk_reader_threads = 1
disk_writer_threads = 1
sync_wait_msec = 50
sync_interval = 0
sync_start_time = 00:00
sync_end_time = 23:59
write_mark_file_freq = 500
disk_recovery_threads = 3
store_path_count = 1
store_path0 = ${path}/storage
subdir_count_per_path = 256
tracker_server = 192.168.31.101:22122
tracker_server = 192.168.31.102:22122
log_level = info
run_by_group =
run_by_user =
allow_hosts = *
file_distribute_path_mode = 0
file_distribute_rotate_count = 100
fsync_after_written_bytes = 0
sync_log_buff_interval = 1
sync_binlog_buff_interval = 1
sync_stat_file_interval = 300
thread_stack_size = 512KB
upload_priority = 10
if_alias_prefix =
check_file_duplicate = 0
file_signature_method = hash
key_namespace = FastDFS
keep_alive = 0
use_access_log = false
rotate_access_log = false
access_log_rotate_time = 00:00
compress_old_access_log = false
compress_access_log_days_before = 7
rotate_error_log = false
error_log_rotate_time = 00:00
compress_old_error_log = false
compress_error_log_days_before = 7
rotate_access_log_size = 0
rotate_error_log_size = 0
log_file_keep_days = 0
file_sync_skip_invalid_record = false
use_connection_pool = true
connection_pool_max_idle_time = 3600
compress_binlog = true
compress_binlog_time = 01:30
check_store_path_mark = true
http.domain_name =
#tracker nginx 负载端口
http.server_port = 18080
EOF

cat >/etc/fdfs/mod_fastdfs.conf <<EOF
connect_timeout=2
network_timeout=30
base_path=/tmp
load_fdfs_parameters_from_tracker=true
storage_sync_file_max_delay = 86400
use_storage_id = false
storage_ids_filename = storage_ids.conf
tracker_server=192.168.31.101:22122
tracker_server=192.168.31.102:22122
storage_server_port=23000
url_have_group_name = true
store_path_count=1
log_level=info
log_filename=
response_mode=proxy
if_alias_prefix=
flv_support = true
flv_extension = flv
group_count = 0
#group_count = 2
#include http.conf

[group1]
group_name=group1
storage_server_port=23000
store_path_count=1
store_path0=${path}/storage

#[group2]
#group_name=group2
#storage_server_port=23000
#store_path_count=1
#store_path0=${path}/storage
EOF

test -f /usr/local/nginx/conf.d/storage.conf ||\
echo "server {
        listen       8888;
        server_name  localhost;

        location ~/group[0-9]/M00 {
            root ${path}/storage;
            ngx_fastdfs_module;
        }
    }" > /usr/local/nginx/conf.d/storage.conf

test -f /usr/local/nginx/conf.d/tracker.conf ||\
echo 'upstream fdfs_group1 {
    server 192.168.31.103:8888 weight=1 max_fails=2 fail_timeout=30s;
    server 192.168.80.104:8888 weight=1 max_fails=2 fail_timeout=30s;
}
upstream fdfs_group2 {
    server 192.168.31.105:8888 weight=1 max_fails=2 fail_timeout=30s;
    server 192.168.31.106:8888 weight=1 max_fails=2 fail_timeout=30s;
}

server {
    listen       18080;
    server_name  localhost;
    location /group1/M00 {
        proxy_next_upstream http_502 http_504 error timeout invalid_header;
        proxy_cache http-cache;
        proxy_cache_valid  200 304 12h;
        proxy_cache_key $uri$is_args$args;
        proxy_pass http://fdfs_group1;
        expires 30d;
    }

    location /group2/M00 {
        proxy_next_upstream http_502 http_504 error timeout invalid_header; proxy_cache http-cache;
        proxy_cache_valid 200 304 12h;
        proxy_cache_key $uri$is_args$args;
        proxy_pass http://fdfs_group2;
        expires 30d;
    }

}' > /usr/local/nginx/conf.d/tracker.conf

mkdir -p ${path}/storage/data
mkdir -p ${path}/tracker
test -L ${path}/storage/data/M00 ||\
ln -s ${path}/storage/data ${path}/storage/data/M00

echo 'tracker高可用'
echo 'upstream fastdfs_tracker {
        server 192.168.31.101:18080 weight=1 max_fails=2 fail_timeout=30s;
        server 192.168.31.102:18080 weight=1 max_fails=2 fail_timeout=30s;
}
    server {
        listen       80;
        server_name  localhost;

        location / {
        proxy_pass http://fastdfs_tracker/;
        }

    }'
#> /usr/local/nginx/conf.d/tracker.conf

echo 'upload file
fdfs_upload_file /etc/fdfs/client.conf filename

'
