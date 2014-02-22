#import <BackBoardServices/BKSDisplayBrightness.h>
#import <SpringBoard/SBBrightnessController.h>
#import <SpringBoard/SBBrightnessHUDView.h>
#import <SpringBoard/SBHUDController.h>
#import <SpringBoard/VolumeControl.h>
#import <version.h>


@interface SBMediaController
+ (id)sharedInstance;
- (BOOL)isRingerMuted;
- (void)setRingerMuted:(BOOL)muted;
- (BOOL)isPlaying;
@end

BOOL isBrightnessMode () {
	if([[%c(SBMediaController) sharedInstance] isRingerMuted] && ![[%c(SBMediaController) sharedInstance] isPlaying])
		return YES;
	return NO;
}




void HBBVSetBrightness(BOOL direction, VolumeControl* volumeControl) {
#ifdef BRIGHTVOL_LEGACY
	[[%c(SBBrightnessController) sharedBrightnessController] adjustBacklightLevel:direction];
#else
	BKSDisplayBrightnessTransactionRef transaction = BKSDisplayBrightnessTransactionCreate(kCFAllocatorDefault);
	CGFloat brightness = BKSDisplayBrightnessGetCurrent() + (direction ? [%c(SBHUDView) progressIndicatorStep] : -[%c(SBHUDView) progressIndicatorStep]);

	if (brightness > 1.f) {
		brightness = 1.f;
	} else if (brightness < 0.f) {
		brightness = 0.f;
	}

	BKSDisplayBrightnessSet(brightness, 1);
	CFRelease(transaction);

	SBBrightnessHUDView *hud = [[[%c(SBBrightnessHUDView) alloc] init] autorelease];
	hud.progress = brightness;
	[[%c(SBHUDController) sharedHUDController] presentHUDView:hud autoDismissWithDelay:1];
#endif

}

%hook VolumeControl

- (void)increaseVolume {
	if (isBrightnessMode()) {
		HBBVSetBrightness(YES, self);
	} else {
		%orig;
	}
}

- (void)decreaseVolume {
	if (isBrightnessMode()) {
		HBBVSetBrightness(NO, self);
	} else {
		%orig;
	}
}

/*
 activator makes pressing volume keys call _changeVolumeBy:
 on ipad. most likely a leftover 3.2 compatibility thing...
*/

- (void)_changeVolumeBy:(CGFloat)by {
	if (isBrightnessMode()) {
		if (by > 0) {
			[self increaseVolume];
		} else {
			[self decreaseVolume];
		}
	} else {
		%orig;
	}
}


%end
