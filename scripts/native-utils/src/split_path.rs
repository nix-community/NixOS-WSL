use std::env;

use clap::Parser;

#[derive(Parser, Debug)]
struct Args {
  #[arg(long)]
  automount_root: String,

  #[arg(long)]
  include_interop: bool,
}

fn main() -> anyhow::Result<()> {
  let args = Args::parse();

  let path = env::var("PATH")?;

  let mut native = vec![];
  let mut interop = vec![];

  for part in path.split(':') {
    if part.starts_with(&args.automount_root) {
      interop.push(part);
    } else {
      native.push(part);
    }
  }

  if args.include_interop {
    native.extend(&interop);
  };

  println!("export PATH='{}'", native.join(":"));
  println!("export WSLPATH='{}'", interop.join(":"));

  Ok(())
}
