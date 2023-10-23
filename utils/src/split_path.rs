use std::{
    env,
    ffi::{OsStr, OsString},
    io::{self, Write},
    os::unix::prelude::{OsStrExt, OsStringExt},
    path::{Path, PathBuf},
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

fn do_split_paths(path: &OsStr, automount_root: &Path, include_interop: bool) -> OsString {
    let mut native = vec![];
    let mut interop = vec![];

    for part in env::split_paths(&path) {
        if part.starts_with(automount_root) {
            interop.push(part);
        } else {
            native.push(part);
        }
    }

    if include_interop {
        native.extend(interop.clone());
    };

    let mut result = OsString::new();
    result.push(build_export("PATH", &native));
    result.push(build_export("WSLPATH", &interop));
    result
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    let path = env::var_os("PATH").expect("PATH is not set, aborting");

    io::stdout()
        .lock()
        .write_all(do_split_paths(&path, &args.automount_root, args.include_interop).as_bytes())?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use std::{ffi::OsString, path::Path};

    use crate::do_split_paths;

    #[test]
    fn simple() {
        assert_eq!(
            do_split_paths(
                &OsString::from("/good/foo:/bad/foo"),
                Path::new("/bad"),
                false
            ),
            OsString::from("export PATH='/good/foo'\nexport WSLPATH='/bad/foo'\n")
        );
    }

    #[test]
    fn exactly_one() {
        assert_eq!(
            do_split_paths(&OsString::from("/good/foo"), Path::new("/bad"), true),
            OsString::from("export PATH='/good/foo'\nexport WSLPATH=''\n")
        );
    }

    #[test]
    fn include_interop() {
        assert_eq!(
            do_split_paths(
                &OsString::from("/good/foo:/bad/foo"),
                Path::new("/bad"),
                true
            ),
            OsString::from("export PATH='/good/foo:/bad/foo'\nexport WSLPATH='/bad/foo'\n")
        );
    }

    #[test]
    fn spicy_escapes() {
        assert_eq!(
            do_split_paths(
                &OsString::from("/good/foo'bar:/bad/foo"),
                Path::new("/bad"),
                true
            ),
            OsString::from(
                "export PATH='/good/foo'\"'\"'bar:/bad/foo'\nexport WSLPATH='/bad/foo'\n"
            )
        );
    }
}
