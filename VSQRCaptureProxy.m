// VSQRCaptureProxy.m
#import "VSQRCaptureProxy.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

// Internal QR scanner view controller ----------------------------------------
@interface _VSQRScannerVC : UIViewController <AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, assign) NSInteger featureIndex;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, copy)   void (^onCode)(NSString *);
@end

@implementation _VSQRScannerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    // Cancel button
    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    cancel.frame     = CGRectMake(16, 48, 80, 36);
    [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancel addTarget:self action:@selector(_cancel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancel];

    [self _startSession];
}

- (void)_startSession {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) return;

    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input || error) return;

    self.session = [AVCaptureSession new];
    [self.session addInput:input];

    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    [self.session addOutput:output];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];

    self.previewLayer            = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.frame      = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];

    [self.session startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)objects
       fromConnection:(AVCaptureConnection *)connection {

    [self.session stopRunning];
    AVMetadataMachineReadableCodeObject *qr =
        (AVMetadataMachineReadableCodeObject *)objects.firstObject;

    NSString *value = qr.stringValue;
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onCode) self.onCode(value ?: @"");
    }];
}

- (void)_cancel {
    [self.session stopRunning];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

// ---------------------------------------------------------------------------
#pragma mark — VSQRCaptureProxy
// ---------------------------------------------------------------------------

@interface VSQRCaptureProxy ()
/// Stores the last raw code string for cross-call validation caching
@property (nonatomic, copy) NSString *lastValidatedCode;
@end

@implementation VSQRCaptureProxy

+ (instancetype)sharedProxy {
    static VSQRCaptureProxy *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [self new]; });
    return instance;
}

// ---------------------------------------------------------------------------
#pragma mark — validCode:
// ---------------------------------------------------------------------------

- (BOOL)validCode:(NSString *)code {
    if (!code.length) return NO;

    // Rules:
    //  1. Must be at least 12 characters
    //  2. Must contain only alphanumeric + hyphen
    //  3. Optionally starts with "VS-"
    if (code.length < 12) return NO;

    NSCharacterSet *allowed  = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *extended = [allowed mutableCopy];
    [(NSMutableCharacterSet *)extended addCharactersInString:@"-"];
    NSCharacterSet *invalid = [extended invertedSet];

    if ([code rangeOfCharacterFromSet:invalid].location != NSNotFound) return NO;

    self.lastValidatedCode = code;
    return YES;
}

// ---------------------------------------------------------------------------
#pragma mark — importedData:code:
// ---------------------------------------------------------------------------

- (void)importedData:(NSDictionary *)data code:(NSString *)code {
    if (![self validCode:code]) {
        NSLog(@"[VSQRCaptureProxy] importedData: invalid code '%@' — rejected.", code);
        return;
    }

    NSLog(@"[VSQRCaptureProxy] importedData received. Code: %@ | Data: %@", code, data);

    // Persist to NSUserDefaults keyed by code
    NSUserDefaults *ud  = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *store = [([ud dictionaryForKey:@"VSImportedData"] ?: @{}) mutableCopy];
    store[code]         = data ?: @{};
    [ud setObject:store forKey:@"VSImportedData"];
    [ud synchronize];

    // Notify listeners
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"VSQRDataImported"
                      object:nil
                    userInfo:@{@"code": code, @"data": data ?: @{}}];
}

// ---------------------------------------------------------------------------
#pragma mark — startNativeQRImportForIndex:
// ---------------------------------------------------------------------------

- (void)startNativeQRImportForIndex:(NSInteger)index {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Check camera permission
        AVAuthorizationStatus status =
            [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

        if (status == AVAuthorizationStatusDenied ||
            status == AVAuthorizationStatusRestricted) {
            NSLog(@"[VSQRCaptureProxy] Camera access denied.");
            return;
        }

        void (^present)(void) = ^{
            UIViewController *root =
                [UIApplication sharedApplication].windows.firstObject.rootViewController;
            while (root.presentedViewController) root = root.presentedViewController;

            _VSQRScannerVC *scanner  = [_VSQRScannerVC new];
            scanner.featureIndex     = index;
            scanner.modalPresentationStyle = UIModalPresentationFullScreen;

            __weak VSQRCaptureProxy *weakSelf = self;
            scanner.onCode = ^(NSString *code) {
                if (!code.length) return;
                if ([weakSelf validCode:code]) {
                    [weakSelf importedData:@{@"featureIndex": @(index)} code:code];
                } else {
                    NSLog(@"[VSQRCaptureProxy] Scanned QR is not a valid VS code: %@", code);
                }
            };

            [root presentViewController:scanner animated:YES completion:nil];
        };

        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                     completionHandler:^(BOOL granted) {
                if (granted) dispatch_async(dispatch_get_main_queue(), present);
            }];
        } else {
            present();
        }
    });
}

@end
