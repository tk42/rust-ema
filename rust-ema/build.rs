fn main() {
    cxx_build::bridge("src/ffi.rs")
        .file("../wrapper/ema_bridge.cpp")
        .flag_if_supported("-std=c++17")
        .include("/usr/local/include") // RT-SDK headers
        .include("/usr/local/include/Cpp-C/Ema/Src/Include") // Ema.h location (installed)
        .include("/usr/local/include/Cpp-C/Ema/Src") // for subheaders like Access/...
        .include("/usr/local/include/Cpp-C/Ema/Src/Rdm/Include") // Rdm headers
        .include("/opt/rtsdk/Cpp-C/Ema/Src/Include") // Ema.h location (build tree)
        .include("/opt/rtsdk/Cpp-C/Ema/Src") // for subheaders
        .include("/opt/rtsdk/Cpp-C/Ema/Src/Rdm/Include") // Rdm headers
        .include("../wrapper")
        .compile("ema_bridge");

    println!("cargo:rustc-link-search=native=/usr/local/lib");
    // RT-SDK build library locations
    println!("cargo:rustc-link-search=native=/opt/rtsdk/Cpp-C/Ema/Libs/DEB12_64_GCC1220/Optimized");
    println!("cargo:rustc-link-search=native=/opt/rtsdk/Cpp-C/Eta/Libs/DEB12_64_GCC1220/Optimized");
    // Additional possible install locations
    println!("cargo:rustc-link-search=native=/usr/local/lib64");
    println!("cargo:rustc-link-search=native=/opt/rtsdk/build");
    println!("cargo:rustc-link-search=native=/opt/rtsdk/build/Lib");
    println!("cargo:rustc-link-search=native=/opt/rtsdk/build/Cpp-C/Ema/Lib");
    println!("cargo:rustc-link-search=native=/opt/rtsdk/build/Cpp-C/Eta/Lib");
    // Link RT-SDK libraries as static
    println!("cargo:rustc-link-lib=static=ema");
    println!("cargo:rustc-link-lib=static=rsslVA");
    println!("cargo:rustc-link-lib=static=rssl");
}
