//
//  AppController.m
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper

#import "AppController.h"
#import "PTHotKeyCenter.h"
#import "PTHotKey.h"

@implementation AppController

- (void)awakeFromNib
{
	[mainWindow center];
}

#pragma mark -

- (IBAction)allowedModifiersChanged:(id)sender
{
	NSUInteger newFlags = 0;
	
	if ([allowedModifiersCommandCheckBox state]) newFlags += NSEventModifierFlagCommand;
	if ([allowedModifiersOptionCheckBox state]) newFlags += NSEventModifierFlagOption;
	if ([allowedModifiersControlCheckBox state]) newFlags += NSEventModifierFlagControl;
	if ([allowedModifiersShiftCheckBox state]) newFlags += NSEventModifierFlagShift;
	
	[shortcutRecorder setAllowedModifierFlags: newFlags];
}

- (IBAction)requiredModifiersChanged:(id)sender
{
	NSUInteger newFlags = 0;
	
	if ([requiredModifiersCommandCheckBox state]) newFlags += NSEventModifierFlagCommand;
	if ([requiredModifiersOptionCheckBox state]) newFlags += NSEventModifierFlagOption;
	if ([requiredModifiersControlCheckBox state]) newFlags += NSEventModifierFlagControl;
	if ([requiredModifiersShiftCheckBox state]) newFlags += NSEventModifierFlagShift;
	
	[shortcutRecorder setRequiredModifierFlags: newFlags];
}

- (IBAction)toggleGlobalHotKey:(id)sender
{
	[shortcutRecorder setCanCaptureGlobalHotKeys:[globalHotKeyCheckBox state]];
	if (globalHotKey != nil)
	{
		[[PTHotKeyCenter sharedCenter] unregisterHotKey: globalHotKey];
		globalHotKey = nil;
	}

	if (![globalHotKeyCheckBox state]) return;

	globalHotKey = [[PTHotKey alloc] initWithIdentifier:@"SRTest"
											   keyCombo:[PTKeyCombo keyComboWithKeyCode:[shortcutRecorder keyCombo].code
																			  modifiers:SRCocoaToCarbonFlags(shortcutRecorder.keyCombo.flags)]];
	
	[globalHotKey setTarget: self];
	[globalHotKey setAction: @selector(hitHotKey:)];
	
	[[PTHotKeyCenter sharedCenter] registerHotKey: globalHotKey];
}

- (IBAction)changeAllowsBareKeys:(id)sender {
	BOOL allowsBareKeys = NO; BOOL recordsEscapeKey = NO;
	NSInteger allowsTag = [allowsBareKeysPopUp selectedTag];
	if (allowsTag > 0)
		allowsBareKeys = YES;
	if (allowsTag > 1)
		recordsEscapeKey = YES;
	
	shortcutRecorder.allowsBareKeys = allowsBareKeys;
	shortcutRecorder.recordsEscapeKey = recordsEscapeKey;
	
	delegateDisallowRecorder.allowsBareKeys = allowsBareKeys;
	delegateDisallowRecorder.recordsEscapeKey = recordsEscapeKey;
}

#pragma mark -

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
	if (aRecorder == shortcutRecorder)
	{
		BOOL isTaken = NO;
		
		SRKeyCombo kc = [delegateDisallowRecorder keyCombo];
		
		if (kc.code == keyCode && kc.flags == flags) isTaken = YES;
		
		*aReason = [delegateDisallowReasonField stringValue];
		
		return isTaken;
	}
	
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(SRKeyCombo)newKeyCombo
{
	if (aRecorder == shortcutRecorder)
	{
		[self toggleGlobalHotKey: aRecorder];
	}
}

- (void)hitHotKey:(PTHotKey *)hotKey
{
	NSMutableAttributedString *logString = [globalHotKeyLogView textStorage];
	[[logString mutableString] appendString: [NSString stringWithFormat: @"%@ pressed. \n", [shortcutRecorder keyComboString]]];
	
	[globalHotKeyLogView scrollPoint: NSMakePoint(0, [globalHotKeyLogView frame].size.height)];
}

@end
