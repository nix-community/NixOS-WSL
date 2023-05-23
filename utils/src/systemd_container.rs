mod wrapper;

use anyhow::{Context, Error, Result};
use nix::{
    libc,
    mount::{mount, MsFlags},
    sched::{setns, unshare, CloneFlags},
    sys::{
        signal::{signal, SigHandler, Signal},
        wait::{waitpid, WaitStatus},
    },
    unistd::{fork, geteuid, setsid, ForkResult, Pid, Uid},
};
use std::{
    env, fs,
    os::unix::process::CommandExt,
    path::Path,
    process::{exit, Command},
    thread::sleep,
    time::Duration,
};

const RUNDIR: &str = "/run/nixos-wsl";

fn run_child_main<F>(f: F) -> !
where
    F: FnOnce() -> Result<i32>,
{
    match f() {
        Ok(status) => exit(status),
        Err(e) => {
            eprintln!("Error: {}", e);
            exit(1);
        }
    }
}

fn is_init_systemd() -> bool {
    // check if we already are inside the container by checking if PID 1 is systemd
    fs::read_to_string("/proc/1/comm")
        .map(|s| s.trim() == "systemd")
        .unwrap_or(false)
}

fn systemd_pid() -> Pid {
    return Pid::from_raw(
        fs::read_to_string(format!("{}/systemd.pid", RUNDIR))
            .map(|s| s.trim().parse::<i32>().unwrap_or(-1))
            .unwrap_or(-1),
    );
}

fn is_systemd_alive() -> bool {
    // check if the process whose PID is stored in RUNDIR/systemd.pid is alive by checking if /proc/$pid exists
    let pid = systemd_pid();
    Path::new(&format!("/proc/{}", pid)).exists()
}

fn run_in_fork<F>(f: F) -> Result<()>
where
    F: FnOnce() -> Result<i32>,
{
    match unsafe { fork().context("When forking")? } {
        ForkResult::Parent { child, .. } => {
            (match waitpid(child, None)? {
                WaitStatus::Exited(_, 0) => Ok(()),
                // WaitStatus::Exited(_, status) => Err(status),
                _ => Err(Error::msg("Child ended with non-zero exit code")),
            })?;

            Ok(())
        }
        ForkResult::Child => run_child_main(f),
    }
}

fn start_systemd() -> Result<()> {
    // delete RUNDIR/system-ready if it exists
    if Path::new(&format!("{}/system-ready", RUNDIR)).exists() {
        fs::remove_file(format!("{}/system-ready", RUNDIR))
            .context("When removing RUNDIR/system-ready")?;
    }

    run_in_fork(|| -> Result<i32> {
        let unshare_flags: CloneFlags = CloneFlags::CLONE_NEWNS | CloneFlags::CLONE_NEWPID;
        unshare(unshare_flags).context("When calling unshare")?;

        match unsafe { fork().context("When forking")? } {
            ForkResult::Parent { child } => {
                // write the child's PID to RUNDIR/systemd.pid
                fs::create_dir_all(RUNDIR).context(format!("When creating {}", RUNDIR))?;
                fs::write(format!("{}/systemd.pid", RUNDIR), format!("{}", child)).context(
                    format!("When writing systemd PID to, {}/systemd.pid", RUNDIR),
                )?;

                Ok(0)
            }
            ForkResult::Child => run_child_main(|| -> Result<i32> {
                // become session leader
                setsid().context("When creating a new session")?;

                // remount /proc for this PID namespace
                mount(
                    Some("proc"),
                    "/proc",
                    Some("proc"),
                    MsFlags::empty(),
                    None::<&str>,
                )
                .context("When mounting /proc")?;

                // catch and ignore sighup
                unsafe { signal(Signal::SIGHUP, SigHandler::SigIgn) }
                    .context("When setting sighup handler")?;

                // change directory to /
                env::set_current_dir("/").context("When changing directory to /")?;

                wrapper::init()?;

                Err(Error::msg("systemd shim exited unexpectedly"))
            }),
        }
    })?;

    // wait for RUNDIR/system-ready to appear
    while !Path::new(&format!("{}/system-ready", RUNDIR)).exists() {
        sleep(Duration::from_millis(1000));
        if !is_systemd_alive() {
            return Err(Error::msg("systemd has exited unexpectedly"));
        }
    }

    Ok(())
}

fn open_fd(path: &str, flags: libc::c_int) -> Result<libc::c_int> {
    let fd = unsafe { libc::open(path.as_ptr() as *const libc::c_char, flags) };
    if fd < 0 {
        return Err(Error::msg(format!(
            "When opening {}: {}",
            path,
            std::io::Error::last_os_error()
        )));
    }

    Ok(fd)
}

fn enter_namespace() -> Result<()> {
    let pid = systemd_pid();

    let pid_fd = open_fd(&format!("/proc/{}/ns/pid", pid), libc::O_RDONLY)
        .context("When opening PID namespace")?;

    let mount_fd = open_fd(&format!("/proc/{}/ns/mnt", pid), libc::O_RDONLY)
        .context("When opening mount namespace")?;

    // enter the namespaces
    setns(pid_fd, CloneFlags::CLONE_NEWPID).context("When entering PID namespace")?;
    setns(mount_fd, CloneFlags::CLONE_NEWNS).context("When entering mount namespace")?;

    Ok(())
}

fn real_main() -> Result<i32> {
    // get the UID of the user who started this program (when running with suid)
    // let user = getuid();
    let pwd = env::current_dir()?;

    // check that the effective UID is 0, crash if it isn't
    if geteuid() != Uid::from_raw(0) {
        panic!("This program must be run as root or the setuid bit must be set");
    }

    // create the rundir if it doesn't exist
    if !Path::new(RUNDIR).exists() {
        fs::create_dir_all(RUNDIR).context("When creating rundir")?;
    }

    if is_init_systemd() {
        // we are already inside the container, just run the command
        // TODO: implement this
        unimplemented!()
    }

    if !is_systemd_alive() {
        start_systemd()?;
    }

    let cleaned_env = env::vars_os()
        .filter(|(k, _)| k != "HOME" && k != "LOGNAME" && k != "SHELL" && k != "USER"); // exclude user-specific variables

    enter_namespace()?;

    let env_out = Command::new("/run/current-system/sw/bin/bash")
        .arg0("/run/current-system/sw/bin/bash")
        .args(&[
            "-c",
            "source /etc/set-environment && exec /run/current-system/sw/bin/env",
        ])
        .env_clear()
        .envs(cleaned_env)
        .output()
        .context("When running env")?
        .stdout;
    let environment = std::str::from_utf8(&env_out)
        .context("When converting env output to utf8")?
        .lines();

    let shell = "/run/current-system/sw/bin/bash"; // TODO: Get the user's shell instead

    let arg_pwd = format!("--working-directory={}", pwd.to_str().unwrap_or("/"));
    let mut args = vec![
        "--quiet",
        "--collect",
        "--wait",
        "--pty",
        "--service-type=exec",
        &arg_pwd,
        "--machine=.host",
    ];
    let args_env_owned = environment
        .map(|line| format!("--setenv={}", line))
        .collect::<Vec<String>>();
    let mut args_env = args_env_owned
        .iter()
        .map(|s| s.as_str())
        .collect::<Vec<&str>>();
    args.append(&mut args_env);

    let mut args_b = vec![
        "/nix/var/nix/profiles/system/sw/bin/runuser",
        "--pty",
        "-u",
        "nixos",
        "--",
        shell,
        "-l",
    ];
    args.append(&mut args_b);
    let args_c = env::args().collect::<Vec<String>>();
    args.append(
        &mut args_c
            .iter()
            .skip(1)
            .map(|s| s.as_str())
            .collect::<Vec<&str>>(),
    );

    match Command::new("/nix/var/nix/profiles/system/sw/bin/systemd-run")
        .arg0("/nix/var/nix/profiles/system/sw/bin/systemd-run")
        .args(args)
        .env_clear()
        .status()
        .context("When running {}")? // insert command
        .code()
    {
        Some(code) => Ok(code),
        None => Err(Error::msg("command exited unexpectedly")), // insert command
    }
}

fn main() -> Result<()> {
    env::set_var("RUST_BACKTRACE", "1");
    kernlog::init().context("When setting up logger...")?;

    exit(real_main()?);
}
