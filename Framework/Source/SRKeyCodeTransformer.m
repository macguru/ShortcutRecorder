//
//  SRKeyCodeTransformer.h
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

#import "SRKeyCodeTransformer.h"
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>
#import "SRCommon.h"
#import "SRValidator.h"

static NSMutableDictionary  *SRKeyCodeTransformerStringToKeyCode	= nil;
static NSDictionary         *SRKeyCodeTransformerKeyCodeToString	= nil;
static NSArray              *SRKeyCodeTransformerPadKeys			= nil;

@interface SRKeyCodeTransformer(Private)
+ (void)regenerateStringToKeyCodeMapping;
@end

#pragma mark -

@implementation SRKeyCodeTransformer

+ (void)initialize;
{
    if (self != [SRKeyCodeTransformer class])
        return;
    
    // Some keys need a special glyph
	SRKeyCodeTransformerKeyCodeToString = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"F1", @(122),
		@"F2", @(120),
		@"F3", @(99),
		@"F4", @(118),
		@"F5", @(96),
		@"F6", @(97),
		@"F7", @(98),
		@"F8", @(100),
		@"F9", @(101),
		@"F10", @(109),
		@"F11", @(103),
		@"F12", @(111),
		@"F13", @(105),
		@"F14", @(107),
		@"F15", @(113),
		@"F16", @(106),
		@"F17", @(64),
		@"F18", @(79),
		@"F19", @(80),
		SRLocalizedString(@"Space"), @(49),
		SRChar(KeyboardDeleteLeftGlyph), @(51),
		SRChar(KeyboardDeleteRightGlyph), @(117),
		SRChar(KeyboardPadClearGlyph), @(71),
		SRChar(KeyboardLeftArrowGlyph), @(123),
		SRChar(KeyboardRightArrowGlyph), @(124),
		SRChar(KeyboardUpArrowGlyph), @(126),
		SRChar(KeyboardDownArrowGlyph), @(125),
		SRChar(KeyboardSoutheastArrowGlyph), @(119),
		SRChar(KeyboardNorthwestArrowGlyph), @(115),
		SRChar(KeyboardEscapeGlyph), @(53),
		SRChar(KeyboardPageDownGlyph), @(121),
		SRChar(KeyboardPageUpGlyph), @(116),
		SRChar(KeyboardReturnR2LGlyph), @(36),
		SRChar(KeyboardReturnGlyph), @(76),
		SRChar(KeyboardTabRightGlyph), @(48),
		SRChar(KeyboardHelpGlyph), @(114),
		nil];    
    
    // We want to identify if the key was pressed on the numpad
	SRKeyCodeTransformerPadKeys = [[NSArray alloc] initWithObjects: 
		@(65), // ,
		@(67), // *
		@(69), // +
		@(75), // /
		@(78), // -
		@(81), // =
		@(82), // 0
		@(83), // 1
		@(84), // 2
		@(85), // 3
		@(86), // 4
		@(87), // 5
		@(88), // 6
		@(89), // 7
		@(91), // 8
		@(92), // 9
		nil];
    
    // generate the string to keycode mapping dict...
    SRKeyCodeTransformerStringToKeyCode = [[NSMutableDictionary alloc] init];
    [self regenerateStringToKeyCodeMapping];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(regenerateStringToKeyCodeMapping) name:(NSString*)kTISNotifySelectedKeyboardInputSourceChanged object:nil];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass;
{
    return [NSString class];
}

//---------------------------------------------------------- 
//  transformedValue: 
//---------------------------------------------------------- 
- (id)transformedValue:(id)value
{
    if (![value isKindOfClass: [NSNumber class]])
        return nil;
    
    // Can be -1 when empty
    NSInteger keyCode = [value shortValue];
	if (keyCode < 0)
		return nil;
	
	// We have some special gylphs for some special keys...
	NSString *unmappedString = SRKeyCodeTransformerKeyCodeToString[@(keyCode)];
	if (unmappedString != nil) 
		return unmappedString;
	
	BOOL isPadKey = [SRKeyCodeTransformerPadKeys containsObject: @(keyCode)];
	
	OSStatus err;
	TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
	if(!tisSource)
		return nil;
	
	CFDataRef layoutData;
	UInt32 keysDown = 0;
	layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
	
	CFRelease(tisSource);
	
	// For non-unicode layouts such as Chinese, Japanese, and Korean, get the ASCII capable layout
	if(!layoutData) {
		tisSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
		layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
		CFRelease(tisSource);
	}

	if (!layoutData)
		return nil;
	
	const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
	
	UniCharCount length = 4, realLength;
	UniChar chars[4];
	
	err = UCKeyTranslate(keyLayout, 
						 keyCode,
						 kUCKeyActionDisplay,
						 0,
						 LMGetKbdType(),
						 kUCKeyTranslateNoDeadKeysBit,
						 &keysDown,
						 length,
						 &realLength,
						 chars);
	
	if (err != noErr) return nil;
	
	NSString *keyString = [[NSString stringWithCharacters:chars length:1] uppercaseString];
	
	return (isPadKey ? [NSString stringWithFormat: SRLocalizedString(@"Pad %@"), keyString] : keyString);
}

//---------------------------------------------------------- 
//  reverseTransformedValue: 
//---------------------------------------------------------- 
- (id)reverseTransformedValue:(id)value
{
    if (![value isKindOfClass:[NSString class]])
        return nil;
    
    // try and retrieve a mapped keycode from the reverse mapping dict...
    return SRKeyCodeTransformerStringToKeyCode[value];
}

@end

#pragma mark -

@implementation SRKeyCodeTransformer(Private)

//---------------------------------------------------------- 
//  regenerateStringToKeyCodeMapping: 
//---------------------------------------------------------- 
+ (void)regenerateStringToKeyCodeMapping
{
    SRKeyCodeTransformer *transformer = [[self alloc] init];
    [SRKeyCodeTransformerStringToKeyCode removeAllObjects];
    
    // loop over every keycode (0 - 127) finding its current string mapping...
    for (NSUInteger i = 0U; i < 128U; i++) {
        NSNumber *keyCode = @(i);
        NSString *string = [transformer transformedValue:keyCode];
        if ((string) && ([string length])) {
            SRKeyCodeTransformerStringToKeyCode[string] = keyCode;
        }
    }
}

@end
