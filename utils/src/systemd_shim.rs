use std::env;

use anyhow::Context;

mod wrapper;

fn main() -> anyhow::Result<()> {
    env::set_var("RUST_BACKTRACE", "1");
    kernlog::init().context("When setting up logger...")?;

    wrapper::init()
}
