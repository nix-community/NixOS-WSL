use anyhow::Context;
use nix::errno::Errno;
use nix::mount::{mount, MsFlags};
use nix::sys::wait::{waitid, Id, WaitPidFlag};
use nix::unistd::Pid;
use std::env;
use std::fs::{create_dir_all, metadata, remove_dir_all, remove_file, OpenOptions};
use std::os::unix::io::{FromRawFd, IntoRawFd};
use std::os::unix::process::CommandExt;
use std::path::Path;
use std::process::{Command, Stdio};

fn unscrew_dev_shm() -> anyhow::Result<()> {
    log::trace!("Unscrewing /dev/shm...");

    let dev_shm = Path::new("/dev/shm");

    if dev_shm.is_symlink() {
        remove_file(dev_shm).context("When removing /dev/shm symlink")?;
    } else if dev_shm.is_dir() {
        remove_dir_all(dev_shm).context("When removing old /dev/shm")?;
    }

    create_dir_all("/dev/shm").context("When creating new /dev/shm")?;
    mount(
        Some("/run/shm"),
        "/dev/shm",
        None::<&str>,
        MsFlags::MS_MOVE,
        None::<&str>,
    )
    .context("When relocating /dev/shm")?;
    mount(
        Some("/dev/shm"),
        "/run/shm",
        None::<&str>,
        MsFlags::MS_BIND,
        None::<&str>,
    )
    .context("When bind mounting /run/shm to /dev/shm")?;

    Ok(())
}

fn real_main() -> anyhow::Result<()> {
    if metadata("/dev/shm")
        .context("When checking /dev/shm")?
        .is_symlink()
    {
        unscrew_dev_shm()?;
    } else {
        log::trace!("/dev/shm is not a symlink, leaving as-is...");
    };

    log::trace!("Remounting / shared...");

    mount(
        None::<&str>,
        "/",
        None::<&str>,
        MsFlags::MS_REC | MsFlags::MS_SHARED,
        None::<&str>,
    )
    .context("When remounting /")?;

    log::trace!("Remounting /nix/store read-only...");

    mount(
        Some("/nix/store"),
        "/nix/store",
        None::<&str>,
        MsFlags::MS_BIND,
        None::<&str>,
    )
    .context("When bind mounting /nix/store")?;

    mount(
        Some("/nix/store"),
        "/nix/store",
        None::<&str>,
        MsFlags::MS_BIND | MsFlags::MS_REMOUNT | MsFlags::MS_RDONLY,
        None::<&str>,
    )
    .context("When remounting /nix/store read-only")?;

    log::trace!("Running activation script...");

    let kmsg_fd = OpenOptions::new()
        .write(true)
        .open("/dev/kmsg")
        .context("When opening /dev/kmsg")?
        .into_raw_fd();

    let child = Command::new("/nix/var/nix/profiles/system/activate")
        .env("LANG", "C.UTF-8")
        // SAFETY: we just opened this
        .stdout(unsafe { Stdio::from_raw_fd(kmsg_fd) })
        .stderr(unsafe { Stdio::from_raw_fd(kmsg_fd) })
        .spawn()
        .context("When activating")?;

    let pid = Pid::from_raw(child.id() as i32);

    // If the child catches SIGCHLD, `waitid` will wait for it to exit, then return ECHILD.
    // Why? Because POSIX is terrible.
    let result = waitid(Id::Pid(pid), WaitPidFlag::WEXITED);
    match result {
        Ok(_) | Err(Errno::ECHILD) => {}
        Err(e) => return Err(e).context("When waiting"),
    };

    log::trace!("Spawning real systemd...");

    // if things go right, we will never return from here
    Err(
        Command::new("/nix/var/nix/profiles/system/systemd/lib/systemd/systemd")
            .arg0(env::args_os().next().expect("arg0 missing"))
            .arg("--log-target=kmsg") // log to dmesg
            .args(env::args_os().skip(1))
            .exec()
            .into(),
    )
}

fn main() {
    env::set_var("RUST_BACKTRACE", "1");
    kernlog::init().expect("Failed to set up logger...");
    let result = real_main();
    log::error!("Error: {:?}", result);
}
