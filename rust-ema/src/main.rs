mod ffi;
use anyhow::Result;
use ffi::*;

fn main() -> Result<()> {
    println!("Hello, world!!!");

    cxx::let_cxx_string!(host = "ADS:14002");
    cxx::let_cxx_string!(service = "ELEKTRON_AD");
    cxx::let_cxx_string!(user = "user1");
    let mut cons = new_consumer(&host, &service, &user);

    if let Some(mut c) = cons.as_mut() {
        cxx::let_cxx_string!(ric = "IBM.N");
        c.request_mp(&ric);
    }

    loop {
        let s = cons.as_mut().unwrap().poll_json();
        if !s.is_empty() {
            println!("{s}");
        }
    }
}
