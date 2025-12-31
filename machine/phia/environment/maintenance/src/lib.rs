use std::path::PathBuf;
use std::sync::LazyLock;

/// `rclone.conf` path
// TODO: avoid hardcode
pub static RCLONE_CONF: LazyLock<PathBuf> = LazyLock::new(|| {
    let conf = PathBuf::from("/etc/rclone.conf");
    assert!(
        conf.exists() && conf.is_file(),
        "Expect rclone.conf to be at {}",
        conf.display()
    );
    conf
});
