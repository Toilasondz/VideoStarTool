// VSToolOverlay.m
#import "VSToolOverlay.h"

static NSString *const kPanelPositionXKey = @"VSPanelPositionX";
static NSString *const kPanelPositionYKey = @"VSPanelPositionY";

// ---------------------------------------------------------------------------
// Layout constants
// ---------------------------------------------------------------------------
static const CGFloat kPanelWidth        = 300.0;
static const CGFloat kPanelHeight       = 420.0;
static const CGFloat kTabBarHeight      = 44.0;
static const CGFloat kCornerRadius      = 16.0;
static const CGFloat kTabCount          = 4.0;

// ---------------------------------------------------------------------------
// Private interface
// ---------------------------------------------------------------------------
@interface VSToolOverlay ()
@property (nonatomic, strong) UIView        *containerView;
@property (nonatomic, strong) UIView        *tabBar;
@property (nonatomic, strong) UIScrollView  *contentScroll;
@property (nonatomic, strong) UIView        *contentView;
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, assign) CGPoint        panStartCenter;
@end

@implementation VSToolOverlay

// ---------------------------------------------------------------------------
#pragma mark — Init
// ---------------------------------------------------------------------------

- (instancetype)initWithFrame:(CGRect)frame {
    // Always use fixed panel size regardless of given frame
    CGRect panelFrame = CGRectMake(frame.origin.x, frame.origin.y,
                                   kPanelWidth, kPanelHeight);
    self = [super initWithFrame:panelFrame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.hidden          = YES;
        _panelOpen           = NO;
        _currentTab          = VSTabHome;

        [self _buildUI];

        // Restore saved position
        CGPoint saved = [self _loadSavedPosition];
        if (!CGPointEqualToPoint(saved, CGPointZero)) {
            self.center = saved;
        }

        // Pan gesture for dragging the header
        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(handlePanelPan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

// ---------------------------------------------------------------------------
#pragma mark — Build UI
// ---------------------------------------------------------------------------

- (void)_buildUI {
    // Background blur card
    UIBlurEffect *blur        = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurV = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurV.frame               = self.bounds;
    blurV.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blurV.layer.cornerRadius  = kCornerRadius;
    blurV.clipsToBounds       = YES;
    [self addSubview:blurV];

    // Tab bar
    _tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kPanelWidth, kTabBarHeight)];
    _tabBar.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.30];
    [self addSubview:_tabBar];

    NSArray<NSString *> *titles = @[@"Home", @"Funcs", @"Settings", @"Dev"];
    NSMutableArray<UIButton *> *btns = [NSMutableArray array];
    CGFloat btnW = kPanelWidth / kTabCount;

    for (NSInteger i = 0; i < (NSInteger)kTabCount; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame     = CGRectMake(i * btnW, 0, btnW, kTabBarHeight);
        btn.tag       = i;
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [btn addTarget:self action:@selector(_tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_tabBar addSubview:btn];
        [btns addObject:btn];
    }
    _tabButtons = [btns copy];

    // Content scroll view
    CGFloat contentY = kTabBarHeight;
    CGFloat contentH = kPanelHeight - kTabBarHeight;
    _contentScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, contentY, kPanelWidth, contentH)];
    _contentScroll.showsVerticalScrollIndicator = YES;
    _contentScroll.alwaysBounceVertical         = YES;
    [self addSubview:_contentScroll];

    [self _reloadContent];
    [self _highlightTab:VSTabHome];
}

// ---------------------------------------------------------------------------
#pragma mark — Tab switching
// ---------------------------------------------------------------------------

- (void)_tabTapped:(UIButton *)sender {
    self.currentTab = (VSTab)sender.tag;
    [self _highlightTab:self.currentTab];
    [self _reloadContent];
}

- (void)_highlightTab:(VSTab)tab {
    for (UIButton *btn in _tabButtons) {
        BOOL active = btn.tag == (NSInteger)tab;
        btn.backgroundColor = active
            ? [[UIColor systemBlueColor] colorWithAlphaComponent:0.40]
            : [UIColor clearColor];
    }
}

- (void)_reloadContent {
    [_contentScroll.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    UIView *content;
    switch (self.currentTab) {
        case VSTabHome:      content = [self renderHomeWithWidth:kPanelWidth];      break;
        case VSTabFunctions: content = [self renderFunctionsWithWidth:kPanelWidth]; break;
        case VSTabSettings:  content = [self renderSettingsWithWidth:kPanelWidth];  break;
        case VSTabDeveloper: content = [self renderDeveloperWithWidth:kPanelWidth]; break;
    }

    if (content) {
        _contentScroll.contentSize = content.bounds.size;
        [_contentScroll addSubview:content];
    }
}

// ---------------------------------------------------------------------------
#pragma mark — renderHomeWithWidth:
// ---------------------------------------------------------------------------

- (UIView *)renderHomeWithWidth:(CGFloat)width {
    UIView *root = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0)];

    UILabel *title = [self _labelWithText:@"VideoStar Tool"
                                     size:18 weight:UIFontWeightBold];
    title.frame    = CGRectMake(16, 16, width - 32, 28);
    [root addSubview:title];

    UILabel *sub = [self _labelWithText:@"Tap a tab above to get started."
                                   size:13 weight:UIFontWeightRegular];
    sub.frame       = CGRectMake(16, 52, width - 32, 44);
    sub.numberOfLines = 0;
    [root addSubview:sub];

    // Version badge
    UILabel *ver = [self _labelWithText:@"v1.0.0" size:11 weight:UIFontWeightLight];
    ver.frame     = CGRectMake(16, 104, 80, 20);
    ver.alpha     = 0.55;
    [root addSubview:ver];

    root.frame = CGRectMake(0, 0, width, 140);
    return root;
}

// ---------------------------------------------------------------------------
#pragma mark — renderFunctionsWithWidth:
// ---------------------------------------------------------------------------

- (UIView *)renderFunctionsWithWidth:(CGFloat)width {
    NSArray<NSString *> *features = @[
        @"QR Import",
        @"Custom Logo",
        @"SSL Override",
        @"Network Log",
        @"Export Data",
        @"Inject Script",
    ];

    CGFloat rowH   = 44.0;
    CGFloat totalH = rowH * features.count;
    UIView *root   = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, totalH)];

    for (NSInteger i = 0; i < (NSInteger)features.count; i++) {
        UIButton *row  = [UIButton buttonWithType:UIButtonTypeSystem];
        row.frame      = CGRectMake(0, i * rowH, width, rowH);
        row.tag        = i;
        row.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        row.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
        [row setTitle:features[i] forState:UIControlStateNormal];
        [row setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        row.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        [row addTarget:self action:@selector(_featureTapped:)
            forControlEvents:UIControlEventTouchUpInside];

        // Separator
        UIView *sep   = [[UIView alloc] initWithFrame:CGRectMake(16, rowH - 0.5, width - 16, 0.5)];
        sep.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12];
        [row addSubview:sep];

        [root addSubview:row];
    }
    return root;
}

- (void)_featureTapped:(UIButton *)sender {
    NSLog(@"[VSToolOverlay] Feature tapped: %ld", (long)sender.tag);
    // Feature-specific dispatch handled by caller / tweak hooks
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"VSFeatureTapped"
                      object:nil
                    userInfo:@{@"index": @(sender.tag)}];
}

// ---------------------------------------------------------------------------
#pragma mark — renderSettingsWithWidth:
// ---------------------------------------------------------------------------

- (UIView *)renderSettingsWithWidth:(CGFloat)width {
    UIView *root = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 200)];

    // -- Custom logo path
    UILabel *logoLabel = [self _labelWithText:@"Custom Logo Path"
                                         size:13 weight:UIFontWeightMedium];
    logoLabel.frame = CGRectMake(16, 12, width - 32, 20);
    [root addSubview:logoLabel];

    UITextField *logoField = [[UITextField alloc] initWithFrame:CGRectMake(16, 36, width - 32, 36)];
    logoField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.10];
    logoField.layer.cornerRadius = 8;
    logoField.textColor          = [UIColor whiteColor];
    logoField.font               = [UIFont systemFontOfSize:13];
    logoField.leftView           = [[UIView alloc] initWithFrame:CGRectMake(0,0,8,0)];
    logoField.leftViewMode       = UITextFieldViewModeAlways;
    logoField.placeholder        = @"/path/to/logo.png";
    logoField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"VSCustomLogoPath"];
    [logoField addTarget:self action:@selector(_logoPathChanged:)
        forControlEvents:UIControlEventEditingDidEnd];
    [root addSubview:logoField];

    // -- Panel opacity
    UILabel *opacityLabel = [self _labelWithText:@"Panel Opacity"
                                            size:13 weight:UIFontWeightMedium];
    opacityLabel.frame = CGRectMake(16, 90, width - 32, 20);
    [root addSubview:opacityLabel];

    UISlider *opacitySlider = [[UISlider alloc] initWithFrame:CGRectMake(16, 114, width - 32, 30)];
    opacitySlider.minimumValue = 0.50;
    opacitySlider.maximumValue = 1.00;
    opacitySlider.value        = (float)([[NSUserDefaults standardUserDefaults]
                                          doubleForKey:@"VSPanelOpacity"] ?: 0.92);
    [opacitySlider addTarget:self action:@selector(_opacityChanged:)
            forControlEvents:UIControlEventValueChanged];
    [root addSubview:opacitySlider];

    return root;
}

- (void)_logoPathChanged:(UITextField *)tf {
    [[NSUserDefaults standardUserDefaults] setObject:tf.text forKey:@"VSCustomLogoPath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)_opacityChanged:(UISlider *)slider {
    self.alpha = slider.value;
    [[NSUserDefaults standardUserDefaults] setDouble:slider.value forKey:@"VSPanelOpacity"];
}

// ---------------------------------------------------------------------------
#pragma mark — renderDeveloperWithWidth:
// ---------------------------------------------------------------------------

- (UIView *)renderDeveloperWithWidth:(CGFloat)width {
    UIView *root = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 260)];

    UILabel *title = [self _labelWithText:@"Developer Tools" size:15 weight:UIFontWeightSemibold];
    title.frame    = CGRectMake(16, 12, width - 32, 22);
    [root addSubview:title];

    NSArray<NSString *> *devActions = @[
        @"Dump Class Hierarchy",
        @"Log Network Requests",
        @"Export NSUserDefaults",
        @"Clear App Cache",
    ];

    CGFloat startY = 48.0;
    CGFloat btnH   = 38.0;
    CGFloat gap    = 10.0;

    for (NSInteger i = 0; i < (NSInteger)devActions.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame     = CGRectMake(16, startY + i * (btnH + gap), width - 32, btnH);
        btn.tag       = 100 + i;
        btn.backgroundColor = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.22];
        btn.layer.cornerRadius = 8;
        btn.layer.borderColor  = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.55].CGColor;
        btn.layer.borderWidth  = 0.5;
        [btn setTitle:devActions[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor systemOrangeColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [btn addTarget:self action:@selector(_devActionTapped:)
            forControlEvents:UIControlEventTouchUpInside];
        [root addSubview:btn];
    }

    return root;
}

- (void)_devActionTapped:(UIButton *)sender {
    NSLog(@"[VSToolOverlay] Dev action: %ld", (long)(sender.tag - 100));
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"VSDevAction"
                      object:nil
                    userInfo:@{@"action": @(sender.tag - 100)}];
}

// ---------------------------------------------------------------------------
#pragma mark — openPanel / closePanel / togglePanel
// ---------------------------------------------------------------------------

- (void)openPanel {
    if (self.isPanelOpen) return;

    self.hidden    = NO;
    self.alpha     = 0.0;
    self.transform = CGAffineTransformMakeScale(0.85, 0.85);

    [UIView animateWithDuration:0.28
                          delay:0
         usingSpringWithDamping:0.75
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.alpha     = [[NSUserDefaults standardUserDefaults] doubleForKey:@"VSPanelOpacity"] ?: 0.92;
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL _) {
        self->_panelOpen = YES;
    }];
}

- (void)closePanel {
    if (!self.isPanelOpen) return;

    [UIView animateWithDuration:0.20
                     animations:^{
        self.alpha     = 0.0;
        self.transform = CGAffineTransformMakeScale(0.85, 0.85);
    } completion:^(BOOL _) {
        self.hidden    = YES;
        self.transform = CGAffineTransformIdentity;
        self->_panelOpen = NO;
    }];
}

- (void)togglePanel {
    self.isPanelOpen ? [self closePanel] : [self openPanel];
}

// ---------------------------------------------------------------------------
#pragma mark — handlePanelPan: / clampPanelPosition / savePanelPosition:
// ---------------------------------------------------------------------------

- (void)handlePanelPan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];

    if (pan.state == UIGestureRecognizerStateBegan) {
        _panStartCenter = self.center;
    }

    CGPoint proposed = CGPointMake(_panStartCenter.x + translation.x,
                                   _panStartCenter.y + translation.y);
    self.center      = [self clampPanelPosition:proposed];

    if (pan.state == UIGestureRecognizerStateEnded ||
        pan.state == UIGestureRecognizerStateCancelled) {
        [self savePanelPosition:self.center];
    }
}

- (CGPoint)clampPanelPosition:(CGPoint)proposed {
    UIWindow *window = self.window ?: [UIApplication sharedApplication].windows.firstObject;
    CGRect   bounds  = window ? window.bounds : UIScreen.mainScreen.bounds;

    UIEdgeInsets safeInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeInsets = window.safeAreaInsets;
    }

    CGFloat halfW  = self.bounds.size.width  / 2.0;
    CGFloat halfH  = self.bounds.size.height / 2.0;
    CGFloat margin = 8.0;

    CGFloat minX = safeInsets.left   + halfW + margin;
    CGFloat maxX = bounds.size.width  - safeInsets.right  - halfW - margin;
    CGFloat minY = safeInsets.top    + halfH + margin;
    CGFloat maxY = bounds.size.height - safeInsets.bottom - halfH - margin;

    return CGPointMake(MAX(minX, MIN(maxX, proposed.x)),
                       MAX(minY, MIN(maxY, proposed.y)));
}

- (void)savePanelPosition:(CGPoint)position {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setDouble:position.x forKey:kPanelPositionXKey];
    [ud setDouble:position.y forKey:kPanelPositionYKey];
    [ud synchronize];
}

- (CGPoint)_loadSavedPosition {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:kPanelPositionXKey]) return CGPointZero;
    return CGPointMake([ud doubleForKey:kPanelPositionXKey],
                       [ud doubleForKey:kPanelPositionYKey]);
}

// ---------------------------------------------------------------------------
#pragma mark — Helpers
// ---------------------------------------------------------------------------

- (UILabel *)_labelWithText:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight {
    UILabel *lbl    = [UILabel new];
    lbl.text        = text;
    lbl.font        = [UIFont systemFontOfSize:size weight:weight];
    lbl.textColor   = [UIColor whiteColor];
    return lbl;
}

@end
