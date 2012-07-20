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
			self.characters];
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
	item.keyEquivalent = self.keyEquivalent ?: [SRStringForKeyCode(self.keyCode) lowercaseString] ?: @"";
	item.keyEquivalentModifierMask = self.modifierFlags;
}

@end
