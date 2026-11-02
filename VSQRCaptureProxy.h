// VSQRCaptureProxy.h — QR-code scanning bridge
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VSQRCaptureProxy : NSObject

/// Shared instance.
+ (instancetype)sharedProxy;

/// Returns YES if the scanned string looks like a valid activation code.
- (BOOL)validCode:(NSString *)code;

/// Process decoded QR data; 'index' identifies which feature slot to activate.
- (void)importedData:(NSDictionary *)data code:(NSString *)code;

/// Launch the native camera-based QR scanner for a specific feature index.
- (void)startNativeQRImportForIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
