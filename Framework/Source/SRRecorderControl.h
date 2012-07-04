//
//  SRRecorderControl.h
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

#import <ShortcutRecorder/SRCommon.h>
@protocol SRRecorderDelegate;


@interface SRRecorderControl : NSControl

@property(nonatomic) SRKeyCombo keyCombo;
@property(nonatomic, copy) NSDictionary *objectValue;

- (NSString *)characters;
- (NSString *)charactersIgnoringModifiers;
- (NSString *)keyComboString;


@property(nonatomic) NSUInteger allowedModifierFlags;
@property(nonatomic) NSUInteger requiredModifierFlags;

@property(nonatomic) BOOL allowsBareKeys;
@property(nonatomic) BOOL recordsEscapeKey;
@property(nonatomic) BOOL canCaptureGlobalHotKeys;

@property(nonatomic, weak) IBOutlet id <SRRecorderDelegate> delegate;

@end

// Delegate Methods
@protocol SRRecorderDelegate <NSObject>

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(SRKeyCombo)newKeyCombo;

@end
