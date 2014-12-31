//
//  MosquittoCallbackBridge.m
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

#import <Foundation/Foundation.h>
#import "MosquittoCallbackBridge.h"
#import "mosquitto.h"
#import "Moscapsule/Moscapsule-Swift.h"

// Local Functions
static int pw_callback(char *, int, int, void *);
static void setMosquittoCallbackBridge(struct mosquitto *);
static void on_connect(struct mosquitto *, void *, int);
static void on_disconnect(struct mosquitto *, void *, int);
static void on_publish(struct mosquitto *, void *, int);
static void on_message(struct mosquitto *, void *, const struct mosquitto_message *);
static void on_subscribe(struct mosquitto *, void *, int, int, const int *);
static void on_unsubscribe(struct mosquitto *, void *, int);
static void on_log(struct mosquitto *, void *, int, const char *);
static const char *LogLevelString(int);
static void log_d(__MosquittoContext *, enum mosq_err_t, NSString *);

void mosquitto_context_setup(const char *clientId, bool cleanSession, __MosquittoContext *mosquittoContext)
{
    mosquittoContext.mosquittoHandler = mosquitto_new(clientId, cleanSession, (__bridge void*)mosquittoContext);
    mosquittoContext.isConnected = false;
    setMosquittoCallbackBridge(mosquittoContext.mosquittoHandler);
}

void mosquitto_context_cleanup(__MosquittoContext *mosquittoContext)
{
    mosquitto_destroy(mosquittoContext.mosquittoHandler);
}

void mosquitto_tls_set_bridge(NSString *cafile, NSString *capath, NSString *certfile, NSString *keyfile, __MosquittoContext *mosquitto_context)
{
    int ret = mosquitto_tls_set(mosquitto_context.mosquittoHandler,
                                cafile != nil ? cafile.UTF8String : nil,
                                capath != nil ? capath.UTF8String : nil,
                                certfile != nil ? certfile.UTF8String : nil,
                                keyfile != nil ? keyfile.UTF8String : nil,
                                pw_callback);

    log_d(mosquitto_context, ret, [NSString stringWithFormat:@"mosquitto_tls_set error (code: %d)", ret]);
}

void mosquitto_tls_opts_set_bridge(int cert_reqs, NSString *tls_version, NSString *ciphers, __MosquittoContext *mosquitto_context)
{
    int ret = mosquitto_tls_opts_set(mosquitto_context.mosquittoHandler, cert_reqs,
                                     tls_version != nil ? tls_version.UTF8String : nil,
                                     ciphers !=  nil ? ciphers.UTF8String : nil);

    log_d(mosquitto_context, ret, [NSString stringWithFormat:@"mosquitto_tls_opts_set error (code: %d)", ret]);
}

void mosquitto_tls_psk_set_bridge(NSString *psk, NSString *identity, NSString *ciphers, __MosquittoContext *mosquitto_context)
{
    int ret = mosquitto_tls_psk_set(mosquitto_context.mosquittoHandler, psk.UTF8String, identity.UTF8String,
                                    ciphers !=  nil ? ciphers.UTF8String : nil);

    log_d(mosquitto_context, ret, [NSString stringWithFormat:@"mosquitto_tls_psk_set error (code: %d)", ret]);
}

static int pw_callback(char *buf, int size, int rwflag, void *obj)
{
    __MosquittoContext *mosquittoContext = (__bridge __MosquittoContext*)obj;
    strncpy(buf, mosquittoContext.keyfile_passwd.UTF8String, size);
    buf[size - 1] = '\0';
    return (int)strlen(buf);
}

static void setMosquittoCallbackBridge(struct mosquitto *mosquittoHandler)
{
    mosquitto_connect_callback_set(mosquittoHandler, on_connect);
    mosquitto_disconnect_callback_set(mosquittoHandler, on_disconnect);
    mosquitto_publish_callback_set(mosquittoHandler, on_publish);
    mosquitto_message_callback_set(mosquittoHandler, on_message);
    mosquitto_subscribe_callback_set(mosquittoHandler, on_subscribe);
    mosquitto_unsubscribe_callback_set(mosquittoHandler, on_unsubscribe);
    mosquitto_log_callback_set(mosquittoHandler, on_log);
}

static void on_connect(struct mosquitto *mosquittoHandler, void *obj, int returnCode)
{
    __MosquittoContext *mosquittoContext = (__bridge __MosquittoContext*)obj;
    mosquittoContext.isConnected = returnCode == 0 ? true : false;
    if (mosquittoContext.onConnectCallback) {
        mosquittoContext.onConnectCallback(returnCode);
    }
}

static void on_disconnect(struct mosquitto *mosquittoHandler, void *obj, int reasonCode)
{
    __MosquittoContext* mosquittoContext = (__bridge __MosquittoContext*)obj;
    mosquittoContext.isConnected = false;
    if (mosquittoContext.onDisconnectCallback) {
        mosquittoContext.onDisconnectCallback(reasonCode);
    }
}

static void on_publish(struct mosquitto *mosquittoHandler, void *obj, int messageId)
{
    __MosquittoContext* mosquittoContext = (__bridge __MosquittoContext*)obj;
    if (mosquittoContext.onPublishCallback) {
        mosquittoContext.onPublishCallback(messageId);
    }
}

static void on_message(struct mosquitto *mosquittoHandler, void *obj, const struct mosquitto_message *message)
{
    __MosquittoContext* mosquittoContext = (__bridge __MosquittoContext*)obj;
    if (mosquittoContext.onMessageCallback) {
        mosquittoContext.onMessageCallback(message);
    }
}

static void on_subscribe(struct mosquitto *mosquittoHandler, void *obj, int messageId, int qos_count, const int *granted_qos)
{
    __MosquittoContext* mosquittoContext = (__bridge __MosquittoContext*)obj;
    if (mosquittoContext.onSubscribeCallback) {
        mosquittoContext.onSubscribeCallback(messageId, qos_count, granted_qos);
    }
}

static void on_unsubscribe(struct mosquitto *mosquittoHandler, void *obj, int messageId)
{
    __MosquittoContext* mosquittoContext = (__bridge __MosquittoContext*)obj;
    if (mosquittoContext.onUnsubscribeCallback) {
        mosquittoContext.onUnsubscribeCallback(messageId);
    }
}

static void on_log(struct mosquitto *mosquittoHandler, void *obj, int logLevel, const char *logMessage)
{
#ifdef DEBUG
    NSLog(@"[MOSQUITTO] %s %s", LogLevelString(logLevel), logMessage);
#endif
}

static const char *LogLevelString(int logLevel)
{
    switch (logLevel) {
        case MOSQ_LOG_INFO:
            return "INFO   ";
        case MOSQ_LOG_NOTICE:
            return "NOTICE ";
        case MOSQ_LOG_WARNING:
            return "WARNING";
        case MOSQ_LOG_ERR:
            return "ERROR  ";
        case MOSQ_LOG_DEBUG:
            return "DEBUG  ";
        default:
            break;
    }
    return "       ";
}

static void log_d(__MosquittoContext *mosquitto_context, enum mosq_err_t mosq_ret, NSString *log)
{
    if(mosq_ret != MOSQ_ERR_SUCCESS) {
        on_log(mosquitto_context.mosquittoHandler, (__bridge void *)(mosquitto_context), MOSQ_LOG_DEBUG, [log UTF8String]);
    }
}