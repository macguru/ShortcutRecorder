//
//  SRRecorderControl.m
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

#import "SRRecorderControl.h"

#import "SRCommon.h"
#import "SRRecorderCell.h"

#define SRFixedHeight	22
#define SRMinWidth		58

@interface SRRecorderControl () <SRRecorderCellDelegate>

- (SRRecorderCell *)cell;
- (void)resetTrackingRects;

@end

@implementation SRRecorderControl

+ (void)initialize
{
    if (self == [SRRecorderControl class]) {
        [self setCellClass: [SRRecorderCell class]];
    }
}

+ (Class)cellClass
{
    return [SRRecorderCell class];
}

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	
	if (self) {
		self.cell.delegate = self;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	
	if (self) {
		self.cell.delegate = self;
	}
	
	return self;
}


#pragma mark *** Cell Behavior ***

- (SRRecorderCell *)cell
{
	return [super cell];
}

- (BOOL)acceptsFirstResponder
{
	// We need keyboard access
    return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	// Allow the control to be activated with the first click on it even if it's window isn't the key window
	return YES;
}

- (BOOL)becomeFirstResponder 
{
    BOOL okToChange = [self.cell becomeFirstResponder];
    if (okToChange) [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    return okToChange;
}

- (BOOL)resignFirstResponder 
{
    BOOL okToChange = [self.cell resignFirstResponder];
    if (okToChange) [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    return okToChange;
}


#pragma mark - Interface

// Prevent from being too small
- (void)setFrameSize:(NSSize)newSize
{
	NSSize correctedSize = newSize;
	correctedSize.height = SRFixedHeight;
	
	if (correctedSize.width < SRMinWidth)
		correctedSize.width = SRMinWidth;
	
	[super setFrameSize: correctedSize];
	[self resetTrackingRects];
}

- (void)setFrame:(NSRect)frameRect
{
	NSRect correctedFrarme = frameRect;
	correctedFrarme.size.height = SRFixedHeight;
	if (correctedFrarme.size.width < SRMinWidth) correctedFrarme.size.width = SRMinWidth;

	[super setFrame: correctedFrarme];
}

- (NSString *)characters
{
	return [self.cell characters];
}

- (NSString *)charactersIgnoringModifiers
{
	return [self.cell charactersIgnoringModifiers];	
}


#pragma mark - Key Interception

// Like most NSControls, pass things on to the cell
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	// Only if we're key, please. Otherwise hitting Space after having
	// tabbed past SRRecorderControl will put you into recording mode.
	if (self.window.firstResponder == self) {
		if ([self.cell performKeyEquivalent:theEvent])
			return YES;
	}

	return [super performKeyEquivalent: theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	[self.cell flagsChanged:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if ([self.cell performKeyEquivalent: theEvent])
        return;
    
    [super keyDown:theEvent];
}


#pragma mark *** Key Combination Control ***

- (NSUInteger)allowedModifierFlags
{
	return [self.cell allowedModifierFlags];
}

- (void)setAllowedModifierFlags:(NSUInteger)flags
{
	[self.cell setAllowedModifierFlags: flags];
}

- (BOOL)allowsBareKeys
{
	return [self.cell allowsBareKeys];
}

- (void)setAllowsBareKeys:(BOOL)nAllowsBareKeys
{
    [self.cell setAllowsBareKeys: nAllowsBareKeys];
}

- (BOOL)recordsEscapeKey
{
	return [self.cell recordsEscapeKey];
}

- (void)setRecordsEscapeKey:(BOOL)nRecordsEscapeKey
{
	[self.cell setRecordsEscapeKey: nRecordsEscapeKey];
}

- (BOOL)canCaptureGlobalHotKeys
{
	return [self.cell canCaptureGlobalHotKeys];
}

- (void)setCanCaptureGlobalHotKeys:(BOOL)inState
{
	[self.cell setCanCaptureGlobalHotKeys:inState];
}

- (NSUInteger)requiredModifierFlags
{
	return [self.cell requiredModifierFlags];
}

- (void)setRequiredModifierFlags:(NSUInteger)flags
{
	[self.cell setRequiredModifierFlags: flags];
}

- (KeyCombo)keyCombo
{
	return [self.cell keyCombo];
}

- (void)setKeyCombo:(KeyCombo)aKeyCombo
{
	[self.cell setKeyCombo: aKeyCombo];
}


#pragma mark - Binding

- (NSDictionary *)objectValue
{
    KeyCombo keyCombo = [self keyCombo];
    if (keyCombo.code == ShortcutRecorderEmptyCode || keyCombo.flags == ShortcutRecorderEmptyFlags)
        return nil;

    return @{@"characters": [self charactersIgnoringModifiers],
            @"keyCode": @(keyCombo.code),
            @"modifierFlags": @(keyCombo.flags)};
}

- (void)setObjectValue:(NSDictionary *)shortcut
{
    KeyCombo keyCombo = SRMakeKeyCombo(ShortcutRecorderEmptyCode, ShortcutRecorderEmptyFlags);
	
    if (shortcut != nil && [shortcut isKindOfClass:[NSDictionary class]]) {
        NSNumber *keyCode = shortcut[@"keyCode"];
        NSNumber *modifierFlags = shortcut[@"modifierFlags"];
		
        if ([keyCode isKindOfClass:[NSNumber class]] && [modifierFlags isKindOfClass:[NSNumber class]]) {
            keyCombo.code = [keyCode integerValue];
            keyCombo.flags = [modifierFlags unsignedIntegerValue];
        }
    }

	[self setKeyCombo: keyCombo];
}

- (Class)valueClassForBinding:(NSString *)binding
{
	if ([binding isEqualToString:@"value"])
		return [NSDictionary class];

	return [super valueClassForBinding:binding];
}

- (NSString *)keyComboString
{
	return [self.cell keyComboString];
}

#pragma mark - Delegate

// Only the delegate will be handled by the control
@synthesize delegate;


- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
	if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorder:isKeyCode:andFlagsTaken:reason:)])
		return [delegate shortcutRecorder:self isKeyCode:keyCode andFlagsTaken:flags reason:aReason];
	else
		return NO;
}

#define NilOrNull(o) ((o) == nil || (id)(o) == [NSNull null])

- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(KeyCombo)newKeyCombo
{
	if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorder:keyComboDidChange:)])
		[delegate shortcutRecorder:self keyComboDidChange:newKeyCombo];

    // propagate view changes to binding (see http://www.tomdalling.com/cocoa/implementing-your-own-cocoa-bindings)
    NSDictionary *bindingInfo = [self infoForBinding:@"value"];
	if (!bindingInfo)
		return;

	// apply the value transformer, if one has been set
    NSDictionary *value = [self objectValue];
	NSDictionary *bindingOptions = bindingInfo[NSOptionsKey];
	if (bindingOptions != nil) {
		NSValueTransformer *transformer = [bindingOptions valueForKey:NSValueTransformerBindingOption];
		if (NilOrNull(transformer)) {
			NSString *transformerName = [bindingOptions valueForKey:NSValueTransformerNameBindingOption];
			if (!NilOrNull(transformerName))
				transformer = [NSValueTransformer valueTransformerForName:transformerName];
		}

		if (!NilOrNull(transformer)) {
			if ([[transformer class] allowsReverseTransformation])
				value = [transformer reverseTransformedValue:value];
			else
				NSLog(@"WARNING: value has value transformer, but it doesn't allow reverse transformations in %s", __PRETTY_FUNCTION__);
		}
	}

	id boundObject = bindingInfo[NSObservedObjectKey];
	if (NilOrNull(boundObject)) {
		NSLog(@"ERROR: NSObservedObjectKey was nil for value binding in %s", __PRETTY_FUNCTION__);
		return;
	}

	NSString *boundKeyPath = bindingInfo[NSObservedKeyPathKey];
    if (NilOrNull(boundKeyPath)) {
		NSLog(@"ERROR: NSObservedKeyPathKey was nil for value binding in %s", __PRETTY_FUNCTION__);
		return;
	}

	[boundObject setValue:value forKeyPath:boundKeyPath];
}

- (void)resetTrackingRects
{
	[self.cell resetTrackingRects];
}

@end
