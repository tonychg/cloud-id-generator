use rand::distributions::Alphanumeric;
use rand::{thread_rng, Rng};

fn main() {
    let mut rng = thread_rng();

    // String:
    let s: String = (&mut rng)
        .sample_iter(Alphanumeric)
        .take(4)
        .map(char::from)
        .collect();

    // Combined values
    println!("{}", s.to_lowercase());
}
