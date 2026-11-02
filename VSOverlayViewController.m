// VSOverlayViewController.m  (includes VSPassthroughWindow implementation)
#import "VSOverlayViewController.h"
#import "VSLogoView.h"
#import "VSToolOverlay.h"

// ---------------------------------------------------------------------------
#pragma mark — VSPassthroughWindow
// ---------------------------------------------------------------------------

@implementation VSPassthroughWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.interceptsTouches) {
        return [super pointInside:point withEvent:event];
    }

    // Walk subviews; only intercept if a subview claims the touch
    for (UIView *sub in self.subviews) {
        if (!sub.isHidden && sub.alpha > 0.01 && sub.userInteractionEnabled) {
            CGPoint converted = [sub convertPoint:point fromView:self];
            if ([sub pointInside:converted withEvent:event]) {
                return YES;
            }
        }
    }
    return NO;
}

@end

// ---------------------------------------------------------------------------
#pragma mark — VSOverlayViewController
// ---------------------------------------------------------------------------

@interface VSOverlayViewController ()
@property (nonatomic, strong) VSPassthroughWindow *overlayWindow;
@end

@implementation VSOverlayViewController

// ---------------------------------------------------------------------------
#pragma mark — Singleton
// ---------------------------------------------------------------------------

+ (instancetype)sharedController {
    static VSOverlayViewController *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [self new]; });
    return instance;
}

// ---------------------------------------------------------------------------
#pragma mark — install / uninstall
// ---------------------------------------------------------------------------

- (void)install {
    if (self.overlayWindow) return; // already installed

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
                if ([s isKindOfClass:[UIWindowScene class]]) {
                    scene = (UIWindowScene *)s;
                    break;
                }
            }
        }

        VSPassthroughWindow *win;
        if (@available(iOS 13.0, *)) {
            win = scene ? [[VSPassthroughWindow alloc] initWithWindowScene:scene]
                        : [[VSPassthroughWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        } else {
            win = [[VSPassthroughWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        }

        win.windowLevel         = UIWindowLevelAlert + 100;
        win.backgroundColor     = [UIColor clearColor];
        win.rootViewController  = self;
        win.interceptsTouches   = NO;
        [win makeKeyAndVisible];
        self.overlayWindow      = win;

        // Add logo
        CGRect  logoFrame = CGRectMake(20, 100, 56, 56);
        VSLogoView *logo  = [[VSLogoView alloc] initWithFrame:logoFrame];

        // Add panel
        CGRect panelFrame = CGRectMake(60, 160, 0, 0); // VSToolOverlay sets its own size
        VSToolOverlay *panel = [[VSToolOverlay alloc] initWithFrame:panelFrame];

        // Link logo → panel
        logo.toolOverlay = panel;

        [self.view addSubview:panel];
        [self.view addSubview:logo]; // logo on top

        self.logoView    = logo;
        self.toolOverlay = panel;
    });
}

- (void)uninstall {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.logoView    removeFromSuperview];
        [self.toolOverlay removeFromSuperview];
        self.overlayWindow.hidden = YES;
        self.overlayWindow        = nil;
    });
}

// ---------------------------------------------------------------------------
#pragma mark — View lifecycle
// ---------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
}

- (BOOL)prefersStatusBarHidden { return NO; }

@end
