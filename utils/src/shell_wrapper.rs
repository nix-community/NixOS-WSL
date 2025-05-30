use anyhow::{anyhow, Context};
use log::{error, info, warn, LevelFilter};
use nix::libc::{sigaction, PT_NULL, SIGCHLD, SIG_IGN};
use nix::sys::inotify::{AddWatchFlags, InitFlags, Inotify};
use std::mem::MaybeUninit;
use std::os::unix::process::CommandExt;
use std::path::Path;
use std::process::Command;
use std::{env, fs::read_link};
use systemd_journal_logger::JournalLog;

fn real_main() -> anyhow::Result<()> {
    let exe = read_link("/proc/self/exe").context("when locating the wrapper binary")?;
    let exe_dir = exe.parent().ok_or(anyhow!(
        "could not locate the wrapper binary's parent directory"
    ))?;

    // Some binaries behave differently depending on the file name they are called with (arg[0]).
    // Therefore we dereference our symlink to get whatever it was originally.
    let shell = read_link(exe_dir.join("shell")).context("when locating the wrapped shell")?;

    if shell.starts_with("/run/current-system/sw/bin/")
        && !Path::new("/run/current-system").exists()
    {
        let inotify = Inotify::init(InitFlags::empty()).context("When initializing inotify")?;

        // Watch changes in /run to re-check if the activation script has finished
        let _wd = inotify.add_watch("/run", AddWatchFlags::IN_CREATE).unwrap();

        let mut warning = false;

        // Check if the activation script has finished by now
        while !Path::new("/run/current-system").exists() {
            if !warning {
                warning = true;
                warn!("Activation script has not finished! Waiting for /run/current-system/sw/bin to exist");
            }
            let _events = inotify
                .read_events()
                .context("When reading inotify events")?;
        }
    }

    // Set the SHELL environment variable to the wrapped shell instead of the wrapper
    let shell_env = env::var_os("SHELL");
    if shell_env == Some(exe.into()) {
        env::set_var("SHELL", &shell);
    }

    // Skip if environment was already set
    if env::var_os("__NIXOS_SET_ENVIRONMENT_DONE") != Some("1".into()) {
        || -> anyhow::Result<()> {
            if !std::path::Path::new("/etc/set-environment").exists() {
                warn!("/etc/set-environment does not exist");
                return Ok(());
            }

            unsafe {
                // WSL starts a single shell under login to make sure that a logind session exists.
                // That shell is started with SIGCHLD ignored
                // If it is, we are probably that shell and can just skip setting the environment
                // sigaction from libc is used here, because the wrapped version from the nix crate does not accept null
                let mut act: sigaction = MaybeUninit::zeroed().assume_init();
                sigaction(SIGCHLD, PT_NULL as *const sigaction, &mut act);
                if act.sa_sigaction == SIG_IGN {
                    info!("SIGCHLD is ignored, skipping setting environment");
                    return Ok(());
                }
            }

            // Load the environment from /etc/set-environment
            let output = Command::new(env!("NIXOS_WSL_SH"))
                .args(&[
                    "-c",
                    &format!(". /etc/set-environment && {} -0", env!("NIXOS_WSL_ENV")),
                ])
                .output()
                .context("when reading /etc/set-environment")?;

            // Parse the output
            let output_string =
                String::from_utf8(output.stdout).context("when decoding the output of env")?;
            let env = output_string
                .split('\0')
                .filter(|entry| !entry.is_empty())
                .map(|entry| {
                    entry
                        .split_once("=")
                        .ok_or(anyhow!("invalid env entry: {}", entry))
                })
                .collect::<Result<Vec<_>, _>>()
                .context("when parsing the output of env")?;

            // Apply the environment variables
            for &(key, val) in &env {
                env::set_var(key, val);
            }

            Ok(())
        }()?;
    }

    let shell_exe = &shell
        .file_name()
        .ok_or(anyhow!("when trying to get the shell's filename"))?
        .to_str()
        .ok_or(anyhow!(
            "when trying to convert the shell's filename to a string"
        ))?
        .to_string();

    let arg0 = if env::args()
        .next()
        .map(|arg| arg.starts_with('-'))
        .unwrap_or(false)
    {
        "-".to_string() + shell_exe.as_str() // prepend "-" to the shell's arg0 to make it a login shell
    } else {
        shell_exe.clone()
    };

    Err(anyhow!(Command::new(&shell)
        .arg0(arg0)
        .args(env::args_os().skip(1))
        .exec())
    .context("when trying to exec the wrapped shell"))
}

fn main() {
    if let Err(err) = JournalLog::new()
        .context("When initializing journal logger")
        .and_then(|logger| {
            logger
                .with_syslog_identifier("shell-wrapper".to_string())
                .install()
                .context("When installing journal logger")
        })
    {
        if nix::unistd::geteuid().is_root() {
            // Journal isn't available during early boot. Try to use kmsg instead
            if let Err(err) = kernlog::init().context("When initializing kernel logger") {
                warn!("Error while setting up kernel logger: {:?}", err);
            }
        } else {
            // Users can't access the kernel log
            warn!("Error while setting up journal logger: {:?}", err);
        }
    }

    log::set_max_level(LevelFilter::Info);

    let result = real_main();

    let err = result.unwrap_err();

    eprintln!("{:?}", &err);

    // Log the error to the journal
    error!("{:?}", &err);
}
