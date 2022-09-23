use anyhow::Context;
use nix::errno::Errno;
use nix::mount::{mount, MsFlags};
use nix::sys::wait::{waitid, Id, WaitPidFlag};
use nix::unistd::Pid;
use std::env;
use std::fs::OpenOptions;
use std::os::unix::io::{FromRawFd, IntoRawFd};
use std::os::unix::process::CommandExt;
use std::process::{Command, Stdio};

fn real_main() -> anyhow::Result<()> {
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
            .args(env::args_os())
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
