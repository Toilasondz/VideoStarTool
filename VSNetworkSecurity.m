// VSNetworkSecurity.m
#import "VSNetworkSecurity.h"
#import <CommonCrypto/CommonHMAC.h>

// Embedded DER-encoded public-key SHA-256 hash (replace with real pin in production)
static const uint8_t kExpectedPinBytes[32] = {
    0xAB,0xCD,0xEF,0x01,0x23,0x45,0x67,0x89,
    0xAB,0xCD,0xEF,0x01,0x23,0x45,0x67,0x89,
    0xAB,0xCD,0xEF,0x01,0x23,0x45,0x67,0x89,
    0xAB,0xCD,0xEF,0x01,0x23,0x45,0x67,0x89,
};

@implementation VSNetworkSecurity

// ---------------------------------------------------------------------------
#pragma mark — Singleton
// ---------------------------------------------------------------------------

+ (instancetype)sharedSecurity {
    static VSNetworkSecurity *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [self new]; });
    return instance;
}

// ---------------------------------------------------------------------------
#pragma mark — VSPinMatchesTrust:
// ---------------------------------------------------------------------------

- (BOOL)VSPinMatchesTrust:(SecTrustRef)serverTrust {
    if (!serverTrust) return NO;

    // Extract the leaf certificate's public-key data and SHA-256 hash it.
    SecCertificateRef cert = SecTrustGetCertificateAtIndex(serverTrust, 0);
    if (!cert) return NO;

    CFDataRef certData = SecCertificateCopyData(cert);
    if (!certData) return NO;

    const uint8_t *bytes = CFDataGetBytePtr(certData);
    CFIndex        len   = CFDataGetLength(certData);

    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(bytes, (CC_LONG)len, digest);
    CFRelease(certData);

    BOOL match = (memcmp(digest, kExpectedPinBytes, CC_SHA256_DIGEST_LENGTH) == 0);
    return match;
}

// ---------------------------------------------------------------------------
#pragma mark — NSURLSessionDelegate — URLSession:didReceiveChallenge:completionHandler:
// ---------------------------------------------------------------------------

- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    NSString *method = challenge.protectionSpace.authenticationMethod;

    if ([method isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef trust = challenge.protectionSpace.serverTrust;

        if ([self VSPinMatchesTrust:trust]) {
            NSURLCredential *cred = [NSURLCredential credentialForTrust:trust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
        } else {
            [self pinFailureDetected];
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

// ---------------------------------------------------------------------------
#pragma mark — pinFailureDetected
// ---------------------------------------------------------------------------

- (void)pinFailureDetected {
    NSLog(@"[VSNetworkSecurity] ⚠️  SSL pin mismatch — possible MITM or bypass attempt.");

    // Post a notification so other subsystems can react (e.g. disable features)
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:@"VSSSLPinFailure"
                          object:self
                        userInfo:@{@"timestamp": [NSDate date]}];
    });
}

// ---------------------------------------------------------------------------
#pragma mark — secretProofForKey:deviceID:timestamp:nonce:
// ---------------------------------------------------------------------------

- (NSString *)secretProofForKey:(NSString *)key
                       deviceID:(NSString *)deviceID
                      timestamp:(NSString *)timestamp
                          nonce:(NSString *)nonce {
    // Message = deviceID | timestamp | nonce  (pipe-separated)
    NSString *message  = [NSString stringWithFormat:@"%@|%@|%@", deviceID, timestamp, nonce];
    NSData   *keyData  = [key     dataUsingEncoding:NSUTF8StringEncoding];
    NSData   *msgData  = [message dataUsingEncoding:NSUTF8StringEncoding];

    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256,
           keyData.bytes, keyData.length,
           msgData.bytes, msgData.length,
           digest);

    NSData *hmacData = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    // URL-safe Base64 (no padding, +→-, /→_)
    NSString *b64 = [hmacData base64EncodedStringWithOptions:0];
    b64 = [b64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    b64 = [b64 stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    b64 = [b64 stringByReplacingOccurrencesOfString:@"=" withString:@""];
    return b64;
}

@end
