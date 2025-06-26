use cxx::{CxxString, UniquePtr};
use std::pin::Pin;

#[cxx::bridge]
mod bridge {
    unsafe extern "C++" {
        include!("ema_bridge.hpp");

        #[namespace = "bridge"]
        type Consumer;

        #[namespace = "bridge"]
        fn new_consumer(host: &CxxString,
                        service: &CxxString,
                        user: &CxxString) -> UniquePtr<Consumer>;

        #[namespace = "bridge"]
        fn request_mp(self: Pin<&mut Consumer>, ric: &CxxString);
        #[namespace = "bridge"]
        fn poll_json(self: Pin<&mut Consumer>) -> String;
    }
}

pub use bridge::*;