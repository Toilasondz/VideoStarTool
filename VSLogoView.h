// VSLogoView.h — Floating draggable logo overlay
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class VSToolOverlay;

@interface VSLogoView : UIImageView

@property (nonatomic, weak) VSToolOverlay *toolOverlay;
@property (nonatomic, assign) CGPoint lastPosition;

/// Designated initializer — creates logo at a saved (or default) position.
- (instancetype)initWithFrame:(CGRect)frame;

/// Pan gesture handler (attached to self).
- (void)handleLogoPan:(UIPanGestureRecognizer *)pan;

/// Tap gesture handler — toggles the tool panel.
- (void)handleLogoTap:(UITapGestureRecognizer *)tap;

/// Keep logo fully inside the screen safe area.
- (CGPoint)clampLogoPosition:(CGPoint)proposed;

/// Persist logo position to NSUserDefaults.
- (void)saveLogoPosition:(CGPoint)position;

/// Load a user-supplied custom logo image (reads path from NSUserDefaults).
- (void)loadCustomLogo;

@end

NS_ASSUME_NONNULL_END
