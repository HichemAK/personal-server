PREFIX="docker exec -u www-data nextcloud-aio-nextcloud"
$PREFIX php occ app:enable encryption files_external
$PREFIX php occ encryption:enable
$PREFIX php occ files_external:create -c host=$MOUNT_ADDRESS -c password=$SFTP_PASS -c port=23 -c root=nextcloud -c user=$MOUNT_USER -- "/storage-box" "sftp" "password::password"
