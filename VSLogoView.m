// VSLogoView.m
#import "VSLogoView.h"
#import "VSToolOverlay.h"

static NSString *const kLogoPositionXKey = @"VSLogoPositionX";
static NSString *const kLogoPositionYKey = @"VSLogoPositionY";
static NSString *const kCustomLogoPathKey = @"VSCustomLogoPath";

@implementation VSLogoView

// ---------------------------------------------------------------------------
#pragma mark — Init
// ---------------------------------------------------------------------------

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.contentMode            = UIViewContentModeScaleAspectFit;
        self.layer.cornerRadius     = frame.size.width / 2.0;
        self.clipsToBounds          = YES;
        self.alpha                  = 0.92;

        // Drop-shadow
        self.layer.shadowColor   = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.45;
        self.layer.shadowRadius  = 6.0;
        self.layer.shadowOffset  = CGSizeMake(0, 3);

        // Default logo (bundled resource or system symbol)
        UIImage *defaultLogo = [UIImage imageNamed:@"VSLogo"]
                            ?: [UIImage systemImageNamed:@"star.circle.fill"];
        self.image = defaultLogo;

        // Load custom logo if the user has set one
        [self loadCustomLogo];

        // Restore saved position
        CGPoint saved = [self _loadSavedPosition];
        if (!CGPointEqualToPoint(saved, CGPointZero)) {
            self.center = saved;
        }

        // Gestures
        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(handleLogoPan:)];
        [self addGestureRecognizer:pan];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(handleLogoTap:)];
        tap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tap];

        [tap requireGestureRecognizerToFail:pan];
    }
    return self;
}

// ---------------------------------------------------------------------------
#pragma mark — handleLogoPan:
// ---------------------------------------------------------------------------

- (void)handleLogoPan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];

    if (pan.state == UIGestureRecognizerStateBegan) {
        self.lastPosition = self.center;
    }

    CGPoint proposed = CGPointMake(self.lastPosition.x + translation.x,
                                   self.lastPosition.y + translation.y);
    CGPoint clamped   = [self clampLogoPosition:proposed];
    self.center       = clamped;

    if (pan.state == UIGestureRecognizerStateEnded ||
        pan.state == UIGestureRecognizerStateCancelled) {
        [self saveLogoPosition:clamped];
    }
}

// ---------------------------------------------------------------------------
#pragma mark — handleLogoTap:
// ---------------------------------------------------------------------------

- (void)handleLogoTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateRecognized) {
        [self.toolOverlay togglePanel];

        // Brief scale pulse
        [UIView animateWithDuration:0.10
                         animations:^{ self.transform = CGAffineTransformMakeScale(0.85, 0.85); }
                         completion:^(BOOL _) {
            [UIView animateWithDuration:0.15
                             animations:^{ self.transform = CGAffineTransformIdentity; }];
        }];
    }
}

// ---------------------------------------------------------------------------
#pragma mark — clampLogoPosition
// ---------------------------------------------------------------------------

- (CGPoint)clampLogoPosition:(CGPoint)proposed {
    UIWindow *window = self.window ?: [UIApplication sharedApplication].windows.firstObject;
    CGRect   bounds  = window ? window.bounds : UIScreen.mainScreen.bounds;

    UIEdgeInsets safeInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeInsets = window.safeAreaInsets;
    }

    CGFloat halfW = self.bounds.size.width  / 2.0;
    CGFloat halfH = self.bounds.size.height / 2.0;
    CGFloat margin = 8.0;

    CGFloat minX = safeInsets.left   + halfW + margin;
    CGFloat maxX = bounds.size.width  - safeInsets.right  - halfW - margin;
    CGFloat minY = safeInsets.top    + halfH + margin;
    CGFloat maxY = bounds.size.height - safeInsets.bottom - halfH - margin;

    return CGPointMake(MAX(minX, MIN(maxX, proposed.x)),
                       MAX(minY, MIN(maxY, proposed.y)));
}

// ---------------------------------------------------------------------------
#pragma mark — saveLogoPosition: / loadSavedPosition
// ---------------------------------------------------------------------------

- (void)saveLogoPosition:(CGPoint)position {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setDouble:position.x forKey:kLogoPositionXKey];
    [ud setDouble:position.y forKey:kLogoPositionYKey];
    [ud synchronize];
}

- (CGPoint)_loadSavedPosition {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:kLogoPositionXKey]) return CGPointZero;
    return CGPointMake([ud doubleForKey:kLogoPositionXKey],
                       [ud doubleForKey:kLogoPositionYKey]);
}

// ---------------------------------------------------------------------------
#pragma mark — loadCustomLogo
// ---------------------------------------------------------------------------

- (void)loadCustomLogo {
    NSString *path = [[NSUserDefaults standardUserDefaults]
                      stringForKey:kCustomLogoPathKey];
    if (!path.length) return;

    UIImage *custom = [UIImage imageWithContentsOfFile:path];
    if (custom) {
        self.image = custom;
    }
}

@end
