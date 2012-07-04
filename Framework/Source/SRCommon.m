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
		(flags & NSControlKeyMask ? SRChar(KeyboardControlGlyph) : @""),
		(flags & NSAlternateKeyMask ? SRChar(KeyboardOptionGlyph) : @""),
		(flags & NSShiftKeyMask ? SRChar(KeyboardShiftGlyph) : @""),
		(flags & NSCommandKeyMask ? SRChar(KeyboardCommandGlyph) : @"")];
	
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
		(flags & NSCommandKeyMask ? SRLocalizedString(@"Command + ") : @""),
		(flags & NSAlternateKeyMask ? SRLocalizedString(@"Option + ") : @""),
		(flags & NSControlKeyMask ? SRLocalizedString(@"Control + ") : @""),
		(flags & NSShiftKeyMask ? SRLocalizedString(@"Shift + ") : @""),
        SRStringForKeyCode(keyCode)];
	return readableString;
}

//---------------------------------------------------------- 
// SRCarbonToCocoaFlags()
//---------------------------------------------------------- 
NSUInteger SRCarbonToCocoaFlags(NSUInteger carbonFlags)
{
	NSUInteger cocoaFlags = ShortcutRecorderEmptyFlags;
	
	if (carbonFlags & cmdKey) cocoaFlags |= NSCommandKeyMask;
	if (carbonFlags & optionKey) cocoaFlags |= NSAlternateKeyMask;
	if (carbonFlags & controlKey) cocoaFlags |= NSControlKeyMask;
	if (carbonFlags & shiftKey) cocoaFlags |= NSShiftKeyMask;
	if (carbonFlags & NSFunctionKeyMask) cocoaFlags += NSFunctionKeyMask;
	
	return cocoaFlags;
}

//---------------------------------------------------------- 
// SRCocoaToCarbonFlags()
//---------------------------------------------------------- 
NSUInteger SRCocoaToCarbonFlags(NSUInteger cocoaFlags)
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	
	if (cocoaFlags & NSCommandKeyMask) carbonFlags |= cmdKey;
	if (cocoaFlags & NSAlternateKeyMask) carbonFlags |= optionKey;
	if (cocoaFlags & NSControlKeyMask) carbonFlags |= controlKey;
	if (cocoaFlags & NSShiftKeyMask) carbonFlags |= shiftKey;
	if (cocoaFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;
	
	return carbonFlags;
}


//---------------------------------------------------------- 
// SRDictionaryFromKeyCombo()
//----------------------------------------------------------
NSDictionary *SRDictionaryFromKeyCombo(SRKeyCombo keyCombo)
{
	if (keyCombo.code == ShortcutRecorderEmptyCode)
		return nil;
	
	return @{ @"keyCode": @(keyCombo.code), @"modifierFlags": @(keyCombo.flags) };
}

//----------------------------------------------------------
// SRKeyComboFromDictionary()
//----------------------------------------------------------
SRKeyCombo SRKeyComboFromDictionary(NSDictionary *dict)
{
	if (!dict)
		return SREmptyKeyCombo;
	
	return SRMakeKeyCombo([dict[@"keyCode"] integerValue], [dict[@"modifierFlags"] unsignedIntegerValue]);
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
    CFLocaleRef locale = CFLocaleCopyCurrent();
	
	TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
    if(!tisSource)
		return FailWithNaiveString;
	
	CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
    if (!layoutData)
		return FailWithNaiveString;
	
	const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    if (!keyLayout)
		return FailWithNaiveString;
	
	EventModifiers modifiers = 0;
	if (cocoaFlags & NSAlternateKeyMask)	modifiers |= optionKey;
	if (cocoaFlags & NSShiftKeyMask)		modifiers |= shiftKey;
	UniCharCount maxStringLength = 4, actualStringLength;
	UniChar unicodeString[4];
	err = UCKeyTranslate(keyLayout, (UInt16)keyCode, kUCKeyActionDisplay, modifiers, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxStringLength, &actualStringLength, unicodeString);
	if(err != noErr)
		return FailWithNaiveString;

	CFStringRef temp = CFStringCreateWithCharacters(kCFAllocatorDefault, unicodeString, 1);
	CFMutableStringRef mutableTemp = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, temp);

	CFStringCapitalize(mutableTemp, locale);

	NSString *resultString = [NSString stringWithString:(__bridge_transfer NSString *)mutableTemp];

	CFRelease(locale);
	if (temp) CFRelease(temp);

	return resultString;
}

