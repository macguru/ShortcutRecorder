//
//  SRKeyCombo.h
//  ShortcutRecorder
//
//  Created by Max Seelemann on 20.07.12.
//
//

@interface SRKeyCombo : NSObject

+ (SRKeyCombo *)keyComboWithKeyCode:(NSUInteger)keyCode keyEquivalent:(NSString *)keyEquivalent andModifierFlags:(NSUInteger)modifierFlags;

// Serialization
+ (SRKeyCombo *)keyComboFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

// Content
@property(nonatomic, readonly) NSUInteger modifierFlags;	// SRKeyComboNoFlags for no flags
@property(nonatomic, readonly) NSUInteger keyCode;		// SRKeyComboNoCode for no code
@property(nonatomic, readonly) NSString *keyEquivalent;	// nil for no code

// Access
@property(nonatomic, readonly) NSString *string;		// Uses keyEquivalent, falls back to key code otherwise
@property(nonatomic, readonly) NSString *characters;	// Uses keyEquivalent, falls back to key code otherwise

- (BOOL)isEqual:(id)object;
- (void)configureMenuItem:(NSMenuItem *)item;

// Utility
+ (BOOL)isFunctionKey:(NSInteger)keyCode;

@end
