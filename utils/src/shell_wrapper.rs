use anyhow::{anyhow, Context};
use nix::libc::{sigaction, PT_NULL, SIGCHLD, SIG_IGN};
use std::mem::MaybeUninit;
use std::os::unix::process::CommandExt;
use std::process::Command;
use std::{env, fs::read_link};

fn real_main() -> anyhow::Result<()> {
    let exe = read_link("/proc/self/exe").context("when locating the wrapper binary")?;
    let exe_dir = exe.parent().ok_or(anyhow!(
        "could not locate the wrapper binary's parent directory"
    ))?;

    // Some binaries behave differently depending on the file name they are called with (arg[0]).
    // Therefore we dereference our symlink to get whatever it was originally.
    let shell = read_link(exe_dir.join("shell")).context("when locating the wrapped shell")?;

    // Set the SHELL environment variable to the wrapped shell instead of the wrapper
    env::set_var("SHELL", &shell);

    // Skip if environment was already set
    if env::var_os("__NIXOS_SET_ENVIRONMENT_DONE") != Some("1".into()) {
        || -> anyhow::Result<()> {
            if !std::path::Path::new("/etc/set-environment").exists() {
                eprintln!("[shell-wrapper] Warning: /etc/set-environment does not exist");
                return Ok(());
            }

            unsafe {
                // WSL starts a single shell under login to make sure that a logind session exists.
                // That shell is started with SIGCHLD ignored
                // If it is, we are probably that shell and can just skip setting the environment
                let mut act: sigaction = MaybeUninit::zeroed().assume_init();
                sigaction(SIGCHLD, PT_NULL as *const sigaction, &mut act);
                if act.sa_sigaction == SIG_IGN {
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
    let result = real_main();

    env::set_var("RUST_BACKTRACE", "1");
    let err = result.unwrap_err();

    eprintln!("[shell-wrapper] Error: {:?}", &err);

    // Write the result to /tmp/shell-wrapper_crash_<pid>.log
    let pid = std::process::id();
    let output_file = format!("/tmp/shell-wrapper_crash_{}.log", pid);
    std::fs::write(output_file, format!("{:?}", &err)).expect("Failed to write crash log to file");
}
