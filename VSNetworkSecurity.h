// VSNetworkSecurity.h — SSL-pinning & HMAC-based request authentication
#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

@interface VSNetworkSecurity : NSObject <NSURLSessionDelegate>

/// Shared singleton.
+ (instancetype)sharedSecurity;

/// Compare an SSL certificate against the embedded pin. Returns YES if they match.
- (BOOL)VSPinMatchesTrust:(SecTrustRef)serverTrust;

/// Called when a pin-bypass / mismatch is detected.
- (void)pinFailureDetected;

/// Build a signed proof string: HMAC-SHA256(key, deviceID|timestamp|nonce), Base64-encoded.
- (NSString *)secretProofForKey:(NSString *)key
                       deviceID:(NSString *)deviceID
                      timestamp:(NSString *)timestamp
                          nonce:(NSString *)nonce;

@end

NS_ASSUME_NONNULL_END
