// VSToolOverlay.h — Floating panel with Home / Functions / Settings / Developer tabs
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VSTab) {
    VSTabHome = 0,
    VSTabFunctions,
    VSTabSettings,
    VSTabDeveloper,
};

@interface VSToolOverlay : UIView

@property (nonatomic, assign) VSTab currentTab;
@property (nonatomic, assign, getter=isPanelOpen) BOOL panelOpen;
@property (nonatomic, assign) CGPoint panelPosition;

/// Open/close/toggle the panel.
- (void)openPanel;
- (void)closePanel;
- (void)togglePanel;

/// Pan gesture handler for dragging the panel.
- (void)handlePanelPan:(UIPanGestureRecognizer *)pan;

/// Keep panel fully inside the screen safe area.
- (CGPoint)clampPanelPosition:(CGPoint)proposed;

/// Persist / restore panel position.
- (void)savePanelPosition:(CGPoint)position;

/// Tab renderers — return a configured UIView for the given panel width.
- (UIView *)renderHomeWithWidth:(CGFloat)width;
- (UIView *)renderFunctionsWithWidth:(CGFloat)width;
- (UIView *)renderSettingsWithWidth:(CGFloat)width;
- (UIView *)renderDeveloperWithWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
