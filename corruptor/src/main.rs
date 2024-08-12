use rand::prelude::*;
use std::env;
use std::fs;
use std::fs::File;
use std::io::Write;

fn main() {
    let args: Vec<String> = env::args().collect();

    let file = args
        .get(1)
        .expect("No file specified\nUsage: corruptor <file name>");

    let mut bytes = fs::read(file.clone()).expect(&format!("Unable to read file: '{}'", file));

    let mut rng = thread_rng();
    let n = rng.gen_range(0..bytes.len());

    let rand_byte = rand::random::<u8>();

    let before = bytes[n];
    bytes[n] = rand_byte;

    let mut output = File::create(&format!("{}.bad", file)).expect("Unable to create new file");

    output.write_all(&bytes).expect("Unable to write to {file}");

    println!(
        "changed byte {:#x} from {:#x} to {:#x}",
        n, before, rand_byte
    );
}
