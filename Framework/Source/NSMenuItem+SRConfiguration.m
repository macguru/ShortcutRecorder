//
//  NSMenuItem+SRConfiguration.m
//  ShortcutRecorder
//
//  Created by Max Seelemann on 04.07.12.
//
//

#import "NSMenuItem+SRConfiguration.h"

@implementation NSMenuItem (SRConfiguration)

- (void)configureWithKeyCombo:(SRKeyCombo)keyCombo
{
	self.keyEquivalent = [SRCharacterForKeyCodeAndCocoaFlags(keyCombo.code, keyCombo.flags) lowercaseString];
	self.keyEquivalentModifierMask = keyCombo.flags;
}

@end
