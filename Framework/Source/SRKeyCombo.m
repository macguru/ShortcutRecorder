//
//  SRKeyCombo.m
//  ShortcutRecorder
//
//  Created by Max Seelemann on 20.07.12.
//
//

#import "SRKeyCombo.h"

#import "SRCommon.h"


@implementation SRKeyCombo

+ (SRKeyCombo *)keyComboWithKeyCode:(NSUInteger)keyCode keyEquivalent:(NSString *)keyEquivalent andModifierFlags:(NSUInteger)modifierFlags
{
	if (keyCode == ShortcutRecorderEmptyCode && !keyEquivalent.length)
		return nil;
	
	SRKeyCombo *combo = [self new];
	
	combo->_modifierFlags = modifierFlags;
	combo->_keyCode = keyCode;
	combo->_keyEquivalent = keyEquivalent;
	
	return combo;
}

+ (SRKeyCombo *)keyComboFromDictionary:(NSDictionary *)dict
{
	if (!dict || !dict.count)
		return nil;
	
	return [self keyComboWithKeyCode:[dict[@"keyCode"] integerValue] keyEquivalent:dict[@"keyEquivalent"] andModifierFlags:[dict[@"modifierFlags"] integerValue]];
}

- (NSDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary new];
	
	dict[@"modifierFlags"] = @(self.modifierFlags);
	if (self.keyCode)
		dict[@"keyCode"] = @(self.keyCode);
	if (self.keyEquivalent)
		dict[@"keyEquivalent"] = self.keyEquivalent;
	
	return dict;
}


#pragma mark - Actions

- (NSString *)string
{
	return [NSString stringWithFormat: @"%@%@",
			SRStringForCocoaModifierFlags(self.modifierFlags),
			self.characters.uppercaseString];
}

- (NSString *)characters
{
	return self.keyEquivalent ?: SRStringForKeyCode(self.keyCode);
}

- (BOOL)isEqual:(id)object
{
	if (![object isKindOfClass: SRKeyCombo.class])
		return NO;
	
	SRKeyCombo *other = object;
	return (self.modifierFlags == other.modifierFlags && [self.characters isEqual: other.characters]);
}

- (void)configureMenuItem:(NSMenuItem *)item
{
	item.keyEquivalentModifierMask = self.modifierFlags;
	
	// Don't show the "FN" modifier in the menu
	if ([self.class isFunctionKey: self.keyCode])
		item.keyEquivalentModifierMask &= ~NSFunctionKeyMask;

	item.keyEquivalent = self.keyEquivalent ?: [self.class menuItemKeyEquivalentForKeyCode: self.keyCode];
}


#pragma mark - Utility

+ (BOOL)isFunctionKey:(NSInteger)keyCode
{
	switch (keyCode) {
		case kVK_F1:
		case kVK_F2:
		case kVK_F3:
		case kVK_F4:
		case kVK_F5:
		case kVK_F6:
		case kVK_F7:
		case kVK_F8:
		case kVK_F10:
		case kVK_F11:
		case kVK_F12:
		case kVK_F13:
		case kVK_F14:
		case kVK_F15:
		case kVK_F16:
		case kVK_F17:
		case kVK_F18:
		case kVK_F19:
		case kVK_F20:
			return YES;
			
		default:
			return NO;
	}
}

+ (NSString *)menuItemKeyEquivalentForKeyCode:(NSInteger)keyCode
{
	// Use special characters for FN keys
	if ([self.class isFunctionKey: keyCode])
		return [NSString stringWithFormat: @"%C", [self.class keyEquivalentForFunctionKey: keyCode]];
	
	// Otherwise, use SRStringForKeyCode
	else
		return SRStringForKeyCode(keyCode).lowercaseString ?: @"";
}

+ (unichar)keyEquivalentForFunctionKey:(NSInteger)keyCode
{
	switch (keyCode) {
		case kVK_F1: return NSF1FunctionKey;
		case kVK_F2: return NSF2FunctionKey;
		case kVK_F3: return NSF3FunctionKey;
		case kVK_F4: return NSF4FunctionKey;
		case kVK_F5: return NSF5FunctionKey;
		case kVK_F6: return NSF6FunctionKey;
		case kVK_F7: return NSF7FunctionKey;
		case kVK_F8: return NSF8FunctionKey;
		case kVK_F10: return NSF10FunctionKey;
		case kVK_F11: return NSF11FunctionKey;
		case kVK_F12: return NSF12FunctionKey;
		case kVK_F13: return NSF13FunctionKey;
		case kVK_F14: return NSF14FunctionKey;
		case kVK_F15: return NSF15FunctionKey;
		case kVK_F16: return NSF16FunctionKey;
		case kVK_F17: return NSF17FunctionKey;
		case kVK_F18: return NSF18FunctionKey;
		case kVK_F19: return NSF19FunctionKey;
		case kVK_F20: return NSF20FunctionKey;
			
		default:
			NSAssert(NO, @"Key code %tu is not a supported function key.", keyCode);
			return 0;
	}
}

@end
