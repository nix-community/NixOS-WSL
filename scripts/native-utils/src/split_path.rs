use std::{
    env,
    ffi::{OsStr, OsString},
    io::{self, Write},
    os::unix::prelude::{OsStrExt, OsStringExt},
    path::PathBuf,
};

use clap::Parser;

#[derive(Parser, Debug)]
struct Args {
    #[arg(long)]
    automount_root: PathBuf,

    #[arg(long)]
    include_interop: bool,
}

const SINGLE_QUOTE: u8 = b'\'';
const DOUBLE_QUOTE: u8 = b'"';

fn shell_escape(s: &OsStr) -> OsString {
    // a shameless ripoff of the Python algorithm:
    // https://github.com/python/cpython/blob/f1f3af7b8245e61a2e0abef03b2c6c5902ed7df8/Lib/shlex.py#L323
    let mut result = Vec::new();

    result.push(SINGLE_QUOTE);

    for &byte in s.as_bytes() {
        result.push(byte);
        if byte == SINGLE_QUOTE {
            result.push(DOUBLE_QUOTE);
            result.push(SINGLE_QUOTE);
            result.push(DOUBLE_QUOTE);
            result.push(SINGLE_QUOTE);
        }
    }

    result.push(SINGLE_QUOTE);

    OsString::from_vec(result)
}

fn build_export(var: &str, paths: &[PathBuf]) -> OsString {
    let mut result = OsString::new();
    result.push("export ");
    result.push(var);
    result.push("=");
    result.push(shell_escape(
        &env::join_paths(paths).expect("paths must be valid"),
    ));
    result.push("\n");
    result
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    let path = env::var("PATH")?;

    let mut native = vec![];
    let mut interop = vec![];

    for part in env::split_paths(&path) {
        if part.starts_with(&args.automount_root) {
            interop.push(part);
        } else {
            native.push(part);
        }
    }

    if args.include_interop {
        native.extend(interop.clone());
    };

    let mut lock = io::stdout().lock();
    lock.write_all(build_export("PATH", &native).as_bytes())?;
    lock.write_all(build_export("WSLPATH", &interop).as_bytes())?;

    Ok(())
}
