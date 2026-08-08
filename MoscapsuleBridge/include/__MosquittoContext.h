#ifndef __MosquittoContext_h
#define __MosquittoContext_h

#import <Foundation/Foundation.h>
#include "mosquitto.h"

@interface __MosquittoContext : NSObject
@property (nonatomic) struct mosquitto *mosquittoHandler;
@property (nonatomic) BOOL isConnected;
@property (nonatomic, copy) NSString *keyfile_passwd;
@property (nonatomic, copy) void (^onConnectCallback)(NSInteger);
@property (nonatomic, copy) void (^onDisconnectCallback)(NSInteger);
@property (nonatomic, copy) void (^onPublishCallback)(NSInteger);
@property (nonatomic, copy) void (^onMessageCallback)(const struct mosquitto_message * _Nonnull);
@property (nonatomic, copy) void (^onSubscribeCallback)(NSInteger, NSInteger, const int * _Nonnull);
@property (nonatomic, copy) void (^onUnsubscribeCallback)(NSInteger);
@end

#endif
