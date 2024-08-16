use clap::Parser;
use color_eyre::eyre::Result;
use rand::prelude::*;
use std::fs;
use std::fs::File;
use std::io::Write;

/// Corrupts a single random byte to a random value in a file
#[derive(Parser)]
#[command(version)]
struct Args {
    /// Path to the file to corrupt
    path: String,
}

fn main() -> Result<()> {
    color_eyre::install()?;
    let args = Args::parse();

    let file = args.path;

    let new_file = randomise_file_byte(file.clone())?;

    println!("saved corrupted file to {}", new_file);
    Ok(())
}

fn randomise_file_byte(file: String) -> Result<String> {
    let mut bytes = fs::read(file.clone())?;

    let mut rng = thread_rng();
    let n = rng.gen_range(0..bytes.len());

    let rand_byte = rand::random::<u8>();

    let before = bytes[n];
    bytes[n] = rand_byte;

    let mut output = File::create(&format!("{}.bad", file))?;

    output.write_all(&bytes)?;

    println!(
        "changed byte {:#x} from {:#x} to {:#x}",
        n, before, rand_byte
    );

    Ok(format!("{}.bad", file))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn invalid_file() {
        let _ =
            randomise_file_byte(String::from("invalid.bin")).expect_err("this should be an error");
    }

    #[test]
    fn out_file_already_exists() {
        File::create("test.bin.bad").expect("Create test file");
        let mut file = File::create("test.bin").expect("Create test file");
        file.write(b"test").expect("Write to test file");
        file.sync_all().expect("Tried to sync fs");
        let _ = randomise_file_byte(String::from("test.bin")).expect("This should overwrite");
        let not_expected = b"test";
        let buf = fs::read("test.bin.bad").expect("Unable to read from bad file");
        assert_ne!(buf, *not_expected);
    }

    #[test]
    fn normal_use() {
        let mut file = File::create("test.bin").expect("Create test file");
        file.write(b"test").expect("Write to test file");
        file.sync_all().expect("Tried to sync fs");
        let _ =
            randomise_file_byte(String::from("test.bin")).expect("This should create the bad file");
        let buf = fs::read("test.bin.bad").expect("Unable to read from bad file");
        assert_ne!(buf, b"test");
    }
}
