// VideoStarTool.m — Tweak entry point (compiled as part of the dylib)
// Hooks into the VideoStar app lifecycle via Cydia Substrate / THEOS.

#import <UIKit/UIKit.h>
#import "VSOverlayViewController.h"
#import "VSNetworkSecurity.h"

// ---------------------------------------------------------------------------
// Constructor — called once when the dylib is injected into the process.
// ---------------------------------------------------------------------------
__attribute__((constructor))
static void VSToolInit(void) {
    @autoreleasepool {
        NSLog(@"[VideoStarTool] dylib injected — initialising overlay.");

        // Start the overlay on the main thread after UIApplication is ready.
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
        ^{
            [[VSOverlayViewController sharedController] install];
            NSLog(@"[VideoStarTool] Overlay installed.");
        });
    }
}

// ---------------------------------------------------------------------------
// Destructor — clean-up if the dylib is ever unloaded.
// ---------------------------------------------------------------------------
__attribute__((destructor))
static void VSToolFini(void) {
    [[VSOverlayViewController sharedController] uninstall];
    NSLog(@"[VideoStarTool] dylib unloaded — overlay removed.");
}
