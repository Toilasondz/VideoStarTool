// VSOverlayViewController.h  &  VSPassthroughWindow.h — Full-screen overlay window
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// ---------------------------------------------------------------------------
// VSPassthroughWindow — transparent window that only intercepts gestures
//                       when the overlay needs them.
// ---------------------------------------------------------------------------
@interface VSPassthroughWindow : UIWindow

/// When NO (default), touches fall through to the app below.
@property (nonatomic, assign) BOOL interceptsTouches;

@end

// ---------------------------------------------------------------------------
// VSOverlayViewController — hosts VSLogoView + VSToolOverlay inside the
//                           passthrough window.
// ---------------------------------------------------------------------------
@interface VSOverlayViewController : UIViewController

/// The floating logo button.
@property (nonatomic, strong) UIView *logoView;       // typed as UIView to avoid circular imports

/// The floating tool panel.
@property (nonatomic, strong) UIView *toolOverlay;    // typed as UIView to avoid circular imports

/// Start / stop the overlay (called from the tweak's constructor / destructor).
+ (instancetype)sharedController;
- (void)install;
- (void)uninstall;

@end

NS_ASSUME_NONNULL_END
