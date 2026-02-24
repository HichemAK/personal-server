PREFIX="docker exec -u www-data nextcloud-aio-nextcloud"
$PREFIX php occ app:enable encryption files_external
$PREFIX php occ encryption:enable

# Register each mount listed in NEXTCLOUD_EXTERNAL_MOUNTS as Nextcloud external storage.
# NEXTCLOUD_EXTERNAL_MOUNTS is a space-separated list of mount slot numbers (e.g. "1 2").
for n in ${NEXTCLOUD_EXTERNAL_MOUNTS:-}; do
    type_var="MOUNT_${n}_TYPE"
    user_var="MOUNT_${n}_USER"
    addr_var="MOUNT_${n}_ADDRESS"
    pass_var="MOUNT_${n}_PASS"
    port_var="MOUNT_${n}_PORT"
    point_var="MOUNT_${n}_POINT"

    mount_type="${!type_var:-}"
    mount_user="${!user_var:-}"
    mount_addr="${!addr_var:-}"
    mount_pass="${!pass_var:-}"
    mount_port="${!port_var:-22}"
    mount_point="${!point_var:-}"

    # Derive a human-readable name from the mount point basename
    mount_name="/$(basename "${mount_point:-mount-${n}}")"

    echo "=== Adding Nextcloud external storage: $mount_name (slot $n, type $mount_type) ==="

    case "$mount_type" in
        sftp)
            $PREFIX php occ files_external:create \
                -c host="$mount_addr" \
                -c user="$mount_user" \
                -c password="$mount_pass" \
                -c port="$mount_port" \
                -c root="nextcloud" \
                -- "$mount_name" "sftp" "password::password"
            ;;
        smb)
            $PREFIX php occ files_external:create \
                -c host="$mount_addr" \
                -c user="$mount_user" \
                -c password="$mount_pass" \
                -c share="backup" \
                -- "$mount_name" "smb" "password::password"
            ;;
        webdav)
            $PREFIX php occ files_external:create \
                -c host="$mount_addr" \
                -c user="$mount_user" \
                -c password="$mount_pass" \
                -c root="nextcloud" \
                -c secure=true \
                -- "$mount_name" "dav" "password::password"
            ;;
        *)
            echo "Warning: Unsupported mount type '$mount_type' for slot $n — skipping external storage."
            ;;
    esac
done
