#ifndef Moscapsule_MosquittoCallbackBridge_h
#define Moscapsule_MosquittoCallbackBridge_h

struct mosquitto;
struct mosquitto_message;

@class __MosquittoContext;

void mosquitto_context_setup(const char *client_id, bool clean_session, __MosquittoContext *mosquittoContext, int protocolVersion);
void mosquitto_context_cleanup(__MosquittoContext *mosquitto_context);

void mosquitto_tls_set_bridge(NSString *cafile, NSString *capath, NSString *certfile, NSString *keyfile, __MosquittoContext *mosquitto_context);
void mosquitto_tls_opts_set_bridge(int cert_reqs, NSString *tls_version, NSString *ciphers, __MosquittoContext *mosquitto_context);
void mosquitto_tls_psk_set_bridge(NSString *psk, NSString *identity, NSString *ciphers, __MosquittoContext *mosquitto_context);
#endif
