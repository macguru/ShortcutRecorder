//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006-2011 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim

#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"
#import "SRValidator.h"

#include <IOKit/hidsystem/IOLLEvent.h>


//---------------------------------------------------------- 
// SRStringForKeyCode()
//---------------------------------------------------------- 
NSString *SRStringForKeyCode(NSInteger keyCode)
{
	if (keyCode == ShortcutRecorderEmptyCode)
		return nil;
	
    return [[NSValueTransformer valueTransformerForName: NSStringFromClass(SRKeyCodeTransformer.class)] transformedValue:[NSNumber numberWithShort:keyCode]];
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlags()
//---------------------------------------------------------- 
NSString *SRStringForCarbonModifierFlags(NSUInteger flags)
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		(flags & controlKey ? SRChar(KeyboardControlGlyph) : @""),
		(flags & optionKey ? SRChar(KeyboardOptionGlyph) : @""),
		(flags & shiftKey ? SRChar(KeyboardShiftGlyph) : @""),
		(flags & cmdKey ? SRChar(KeyboardCommandGlyph) : @"")];
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString *SRStringForCarbonModifierFlagsAndKeyCode(NSUInteger flags, NSInteger keyCode)
{
	if (keyCode == ShortcutRecorderEmptyCode)
		return nil;
	
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCarbonModifierFlags(flags), 
        SRStringForKeyCode(keyCode)];
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlags()
//---------------------------------------------------------- 
NSString *SRStringForCocoaModifierFlags(NSUInteger flags)
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		(flags & NSEventModifierFlagControl ? SRChar(KeyboardControlGlyph) : @""),
		(flags & NSEventModifierFlagOption ? SRChar(KeyboardOptionGlyph) : @""),
		(flags & NSEventModifierFlagShift ? SRChar(KeyboardShiftGlyph) : @""),
		(flags & NSEventModifierFlagCommand ? SRChar(KeyboardCommandGlyph) : @"")];
	
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString *SRStringForCocoaModifierFlagsAndKeyCode(NSUInteger flags, NSInteger keyCode)
{
	if (keyCode == ShortcutRecorderEmptyCode)
		return nil;
	
    return [NSString stringWithFormat: @"%@%@",
        SRStringForCocoaModifierFlags(flags),
        SRStringForKeyCode(keyCode)];
}

//---------------------------------------------------------- 
// SRReadableStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString *SRReadableStringForCarbonModifierFlagsAndKeyCode(NSUInteger flags, NSInteger keyCode)
{
	if (keyCode == ShortcutRecorderEmptyCode)
		return nil;
	
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		(flags & cmdKey ? SRLocalizedString(@"Command + ") : @""),
		(flags & optionKey ? SRLocalizedString(@"Option + ") : @""),
		(flags & controlKey ? SRLocalizedString(@"Control + ") : @""),
		(flags & shiftKey ? SRLocalizedString(@"Shift + ") : @""),
        SRStringForKeyCode(keyCode)];
	return readableString;    
}

//---------------------------------------------------------- 
// SRReadableStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString *SRReadableStringForCocoaModifierFlagsAndKeyCode(NSUInteger flags, NSInteger keyCode)
{
	if (keyCode == ShortcutRecorderEmptyCode)
		return nil;
	
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		(flags & NSEventModifierFlagCommand ? SRLocalizedString(@"Command + ") : @""),
		(flags & NSEventModifierFlagOption ? SRLocalizedString(@"Option + ") : @""),
		(flags & NSEventModifierFlagControl ? SRLocalizedString(@"Control + ") : @""),
		(flags & NSEventModifierFlagShift ? SRLocalizedString(@"Shift + ") : @""),
        SRStringForKeyCode(keyCode)];
	return readableString;
}

//---------------------------------------------------------- 
// SRCarbonToCocoaFlags()
//---------------------------------------------------------- 
NSUInteger SRCarbonToCocoaFlags(NSUInteger carbonFlags)
{
	NSUInteger cocoaFlags = ShortcutRecorderEmptyFlags;
	
	if (carbonFlags & cmdKey) cocoaFlags |= NSEventModifierFlagCommand;
	if (carbonFlags & optionKey) cocoaFlags |= NSEventModifierFlagOption;
	if (carbonFlags & controlKey) cocoaFlags |= NSEventModifierFlagControl;
	if (carbonFlags & shiftKey) cocoaFlags |= NSEventModifierFlagShift;
	if (carbonFlags & NSEventModifierFlagFunction) cocoaFlags += NSEventModifierFlagFunction;
	
	return cocoaFlags;
}

//---------------------------------------------------------- 
// SRCocoaToCarbonFlags()
//---------------------------------------------------------- 
NSUInteger SRCocoaToCarbonFlags(NSUInteger cocoaFlags)
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	
	if (cocoaFlags & NSEventModifierFlagCommand) carbonFlags |= cmdKey;
	if (cocoaFlags & NSEventModifierFlagOption) carbonFlags |= optionKey;
	if (cocoaFlags & NSEventModifierFlagControl) carbonFlags |= controlKey;
	if (cocoaFlags & NSEventModifierFlagShift) carbonFlags |= shiftKey;
	if (cocoaFlags & NSEventModifierFlagFunction) carbonFlags |= NSEventModifierFlagFunction;
	
	return carbonFlags;
}

//----------------------------------------------------------
// SRCharacterForKeyCodeAndCarbonFlags()
//----------------------------------------------------------
NSString *SRCharacterForKeyCodeAndCarbonFlags(NSInteger keyCode, NSUInteger carbonFlags)
{
	return SRCharacterForKeyCodeAndCocoaFlags(keyCode, SRCarbonToCocoaFlags(carbonFlags));
}

//---------------------------------------------------------- 
// SRCharacterForKeyCodeAndCocoaFlags()
//----------------------------------------------------------
NSString *SRCharacterForKeyCodeAndCocoaFlags(NSInteger keyCode, NSUInteger cocoaFlags) {
	// Fall back to string based on key code:
#define	FailWithNaiveString SRStringForKeyCode(keyCode)
	
	UInt32              deadKeyState;
    OSStatus err = noErr;
	
	TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
    if (!tisSource)
		return FailWithNaiveString;
	
	CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
    if (!layoutData)
		return FailWithNaiveString;
	
	const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    if (!keyLayout)
		return FailWithNaiveString;
	
	EventModifiers modifiers = 0;
	if (cocoaFlags & NSEventModifierFlagOption)	modifiers |= optionKey;
	if (cocoaFlags & NSEventModifierFlagShift)		modifiers |= shiftKey;
	UniCharCount maxStringLength = 4, actualStringLength;
	UniChar unicodeString[4];
	err = UCKeyTranslate(keyLayout, (UInt16)keyCode, kUCKeyActionDisplay, modifiers, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStringLength, &actualStringLength, unicodeString);
	if(err != noErr)
		return FailWithNaiveString;

	CFStringRef temp = CFStringCreateWithCharacters(kCFAllocatorDefault, unicodeString, 1);
	CFMutableStringRef mutableTemp = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, temp);
	
    CFLocaleRef locale = CFLocaleCopyCurrent();
	CFStringCapitalize(mutableTemp, locale);
	CFRelease(locale);

	NSString *resultString = [NSString stringWithString:(__bridge_transfer NSString *)mutableTemp];

	if (temp) CFRelease(temp);

	return resultString;
}

