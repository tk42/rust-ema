// wrapper/ema_bridge.hpp
#pragma once
#include <Ema.h>          // RT-SDK headers (in /usr/local/include)
#include <memory>
#include <string>
#include <mutex>
#include "rust/cxx.h"

namespace bridge {

// simple ring-buffered client -----------------------------------------------
class JsonClient : public refinitiv::ema::access::OmmConsumerClient {
public:
    std::string pop();                    // ↓ implementation in .cpp
private:
    void onUpdateMsg(const refinitiv::ema::access::UpdateMsg&, 
                     const refinitiv::ema::access::OmmConsumerEvent&) override;
    std::mutex mtx_;
    std::string last_;
};

// façade exposed to Rust -----------------------------------------------------
class Consumer {
public:
    Consumer(const std::string& host,
             const std::string& service,
             const std::string& user);

    void request_mp(const std::string& ric);   // send ReqMsg
    rust::String poll_json();                   // non-blocking

private:
    std::shared_ptr<JsonClient> client_;
    std::unique_ptr<refinitiv::ema::access::OmmConsumer> omm_;
};

// Factory function exposed to Rust (cxx bridge)
std::unique_ptr<Consumer> new_consumer(const std::string& host,
                                      const std::string& service,
                                      const std::string& user);

} // namespace bridge