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
#import <ShortcutRecorder/SRKeyCombo.h>
@protocol SRRecorderDelegate;


@interface SRRecorderControl : NSControl

@property(nonatomic, strong) SRKeyCombo *shortcut;
@property(copy) NSDictionary *objectValue; // Exposes binding @"value" for a dictionary rep of the shortcut

@property(nonatomic) NSUInteger allowedModifierFlags;
@property(nonatomic) NSUInteger requiredModifierFlags;

@property(nonatomic) BOOL allowsBareKeys;
@property(nonatomic) BOOL recordsEscapeKey;
@property(nonatomic) BOOL canCaptureGlobalHotKeys;

@property(nonatomic, unsafe_unretained) IBOutlet id <SRRecorderDelegate> delegate;

@end

// Delegate Methods
@protocol SRRecorderDelegate <NSObject>
@optional

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder areModifierFlagsValid:(NSUInteger)modifierFlags;
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(SRKeyCombo *)newKeyCombo;

@end
