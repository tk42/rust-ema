// wrapper/ema_bridge.cpp
#include "ema_bridge.hpp"
#include <utility> // for std::exchange
#include <nlohmann/json.hpp>   // header-only JSON (tiny, safe to vendor)

using namespace refinitiv::ema::access;
using nlohmann::json;
namespace bridge {

// -------- JsonClient --------------------------------------------------------
void JsonClient::onUpdateMsg(const UpdateMsg& msg, const OmmConsumerEvent&) {
    json j;
    j["ric"]     = msg.getName();
    j["service"] = msg.getServiceName();
    j["fields"]  = "…";            // → field list serialization omitted †
    std::lock_guard lk(mtx_);
    last_ = j.dump();
}

std::string JsonClient::pop() {
    std::lock_guard lk(mtx_);
    return std::exchange(last_, "");
}

// -------- Consumer ----------------------------------------------------------
Consumer::Consumer(const std::string& host,
                   const std::string& service,
                   const std::string& user) : client_(std::make_shared<JsonClient>())
{
    OmmConsumerConfig cfg;
    cfg.host(host.c_str()).username(user.c_str()).operationModel(OmmConsumerConfig::UserDispatchEnum);
    omm_ = std::make_unique<OmmConsumer>(cfg, *client_);
    omm_->registerClient(
        ReqMsg().serviceName(service.c_str()).name("PING"), *client_); // dummy ping
}

void Consumer::request_mp(const std::string& ric) {
    omm_->registerClient(
        ReqMsg().serviceName("ELEKTRON_AD").name(ric.c_str()), *client_);
}

rust::String Consumer::poll_json() {
    omm_->dispatch(10);          // non-blocking 10 ms
    return rust::String(client_->pop());
}

std::unique_ptr<Consumer> new_consumer(const std::string& host,
                                      const std::string& service,
                                      const std::string& user) {
    return std::make_unique<Consumer>(host, service, user);
}

} // namespace bridge