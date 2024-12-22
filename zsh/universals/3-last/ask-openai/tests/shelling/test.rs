use std::env;
use std::process::{Command, exit};

fn main() {
    // Collect command-line arguments
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        eprintln!("Usage: {} <security-command-args>", args[0]);
        exit(1);
    }

    // Construct the `security` command and its arguments
    let output = Command::new("security")
        .args(&args[1..])
        .output();

    match output {
        Ok(output) => {
            // Print stdout
            if !output.stdout.is_empty() {
                println!("{}", String::from_utf8_lossy(&output.stdout));
            }
            // Print stderr
            if !output.stderr.is_empty() {
                eprintln!("{}", String::from_utf8_lossy(&output.stderr));
            }
            // Exit with the same code as the `security` command
            exit(output.status.code().unwrap_or(1));
        }
        Err(e) => {
            eprintln!("Failed to execute `security`: {}", e);
            exit(1);
        }
    }
}
