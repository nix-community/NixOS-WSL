use anyhow::{anyhow, Context};
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
        // Load the environment from /etc/set-environment
        let output = Command::new("/bin/sh")
            .args(&["-c", ". /etc/set-environment && /usr/bin/env -0"])
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
    }

    Err(anyhow!(Command::new(&shell)
        .arg0(shell)
        .args(env::args_os().skip(1))
        .exec())
    .context("when trying to exec the wrapped shell"))
}

fn main() {
    let result = real_main();

    env::set_var("RUST_BACKTRACE", "1");
    eprintln!("[shell-wrapper] Error: {:?}", result.unwrap_err());
}
