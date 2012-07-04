//
//  SRRecorderCell.h
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//		Max Seelemann

#import "SRCommon.h"
@protocol SRRecorderCellDelegate;


@interface SRRecorderCell : NSActionCell <NSCoding>

@property(nonatomic) SRKeyCombo keyCombo;

@property(nonatomic) NSUInteger allowedModifierFlags;
@property(nonatomic) NSUInteger requiredModifierFlags;

@property(nonatomic) BOOL allowsBareKeys;	// Setting to NO also sets recordsEscapeKey to NO
@property(nonatomic) BOOL recordsEscapeKey;	// Setting to YES also sets allowsBareKeys to YES
@property(nonatomic) BOOL canCaptureGlobalHotKeys;


// Event handling
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (void)resetTrackingRects;

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)flagsChanged:(NSEvent *)theEvent;


// Other
@property(nonatomic, weak) id <SRRecorderCellDelegate> delegate;

- (NSString *)characters;
- (NSString *)charactersIgnoringModifiers;
- (NSString *)keyComboString;

@end

@protocol SRRecorderCellDelegate <NSObject>

@optional
- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;
- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(SRKeyCombo)newCombo;

@end
