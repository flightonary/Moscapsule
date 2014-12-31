//
//  MosquittoCallbackBridge.h
//  Moscapsule
//
//  Created by flightonary on 2014/11/25.
//
//    The MIT License (MIT)
//
//    Copyright (c) 2014 tonary <jetBeaver@gmail.com>. All rights reserved.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of
//    this software and associated documentation files (the "Software"), to deal in
//    the Software without restriction, including without limitation the rights to
//    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//    the Software, and to permit persons to whom the Software is furnished to do so,
//    subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#ifndef Moscapsule_MosquittoCallbackBridge_h
#define Moscapsule_MosquittoCallbackBridge_h

struct mosquitto;
struct mosquitto_message;

@class __MosquittoContext;

void mosquitto_context_setup(const char *client_id, bool clean_session, __MosquittoContext *mosquittoContext);
void mosquitto_context_cleanup(__MosquittoContext *mosquitto_context);

void mosquitto_tls_set_bridge(NSString *cafile, NSString *capath, NSString *certfile, NSString *keyfile, __MosquittoContext *mosquitto_context);
void mosquitto_tls_opts_set_bridge(int cert_reqs, NSString *tls_version, NSString *ciphers, __MosquittoContext *mosquitto_context);
void mosquitto_tls_psk_set_bridge(NSString *psk, NSString *identity, NSString *ciphers, __MosquittoContext *mosquitto_context);
#endif
