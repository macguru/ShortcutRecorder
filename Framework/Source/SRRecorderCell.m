//
//  SRRecorderCell.m
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

#import "SRRecorderCell.h"
#import "SRRecorderControl.h"
#import "SRKeyCodeTransformer.h"
#import "SRValidator.h"

@interface SRRecorderCell () <SRValidatorDelegate>
{	
	NSGradient          *recordingGradient;
	
	BOOL                _isRecording;
	BOOL                _mouseInsideTrackingArea;
	BOOL                _mouseDown;
	
	NSTrackingRectTag   _removeTrackingRectTag;
	NSTrackingRectTag   _snapbackTrackingRectTag;
	
	NSUInteger			_recordingFlags;
	
    SRValidator         *validator;
    
	void				*hotKeyModeToken;
}

- (void)_privateInit;
- (void)_createGradient;
- (void)_startRecording;
- (void)_endRecording;

- (NSRect)_removeButtonRectForFrame:(NSRect)cellFrame;
- (NSRect)_snapbackRectForFrame:(NSRect)cellFrame;

- (NSUInteger)_filteredCocoaFlags:(NSUInteger)flags;
- (NSUInteger)_filteredCocoaToCarbonFlags:(NSUInteger)cocoaFlags;
- (BOOL)_validModifierFlags:(NSUInteger)flags;

- (BOOL)_isEmpty;
@end

#pragma mark -

@implementation SRRecorderCell

@synthesize allowsBareKeys, recordsEscapeKey, requiredModifierFlags, allowedModifierFlags, canCaptureGlobalHotKeys, delegate, keyCombo;

- (id)init
{
    self = [super init];
	
	[self _privateInit];
	
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark *** Coding Support ***

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	
	if (self) {
		[self _privateInit];
		NSAssert([aDecoder allowsKeyedCoding], @"Keyed Coding required!");
		
		keyCombo.code = [[aDecoder decodeObjectForKey: @"keyComboCode"] shortValue];
		keyCombo.flags = [[aDecoder decodeObjectForKey: @"keyComboFlags"] unsignedIntegerValue];
		
		allowedModifierFlags = [[aDecoder decodeObjectForKey: @"allowedModifierFlags"] unsignedIntegerValue];
		allowedModifierFlags |= NSFunctionKeyMask;
		
		requiredModifierFlags = [[aDecoder decodeObjectForKey: @"requiredModifierFlags"] unsignedIntegerValue];
		
		allowsBareKeys = [[aDecoder decodeObjectForKey:@"allowsBareKeys"] boolValue];
		recordsEscapeKey = [[aDecoder decodeObjectForKey:@"recordsEscapeKey"] boolValue];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder: aCoder];
	
	NSAssert([aCoder allowsKeyedCoding], @"Keyed coder required");
	
	[aCoder encodeObject:[NSNumber numberWithShort: keyCombo.code] forKey:@"keyComboCode"];
	[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:keyCombo.flags] forKey:@"keyComboFlags"];
	
	[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:allowedModifierFlags] forKey:@"allowedModifierFlags"];
	[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:requiredModifierFlags] forKey:@"requiredModifierFlags"];
	
	[aCoder encodeObject:[NSNumber numberWithBool: allowsBareKeys] forKey:@"allowsBareKeys"];
	[aCoder encodeObject:[NSNumber numberWithBool: recordsEscapeKey] forKey:@"recordsEscapeKey"];
}

- (id)copyWithZone:(NSZone *)zone
{
    SRRecorderCell *cell;
    cell = (SRRecorderCell *)[super copyWithZone: zone];
	
	cell->recordingGradient = recordingGradient;

	cell->_isRecording = _isRecording;
	cell->_mouseInsideTrackingArea = _mouseInsideTrackingArea;
	cell->_mouseDown = _mouseDown;

	cell->_removeTrackingRectTag = _removeTrackingRectTag;
	cell->_snapbackTrackingRectTag = _snapbackTrackingRectTag;

	cell->keyCombo = keyCombo;

	cell->allowedModifierFlags = allowedModifierFlags;
	cell->requiredModifierFlags = requiredModifierFlags;
	cell->_recordingFlags = _recordingFlags;
	
	cell->allowsBareKeys = allowsBareKeys;
	cell->recordsEscapeKey = recordsEscapeKey;
    
	cell->delegate = delegate;
	
    return cell;
}

#pragma mark *** Drawing ***

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	CGFloat radius = 0;

		cellFrame = NSInsetRect(cellFrame,0.5f,0.5f);
		
		NSRect whiteRect = cellFrame;
		NSBezierPath *roundedRect;
		
		BOOL isVaguelyRecording = _isRecording;
		
		CGFloat alphaRecording = 1.0f; CGFloat alphaView = 1.0f;
		
	// Draw white rounded box
		radius = NSHeight(whiteRect) / 2.0f;
		roundedRect = [NSBezierPath bezierPathWithRoundedRect:whiteRect xRadius:radius yRadius:radius];
		[[NSColor whiteColor] set];
		[[NSGraphicsContext currentContext] saveGraphicsState];
		[roundedRect fill];
		[[NSColor windowFrameColor] set];
		[roundedRect stroke];
		[roundedRect addClip];
		
		if (_isRecording) 
		{
			NSRect snapBackRect = [self _snapbackRectForFrame: cellFrame];
//		NSLog(@"snapbackrect: %@; offset: %@", NSStringFromRect([self _snapbackRectForFrame: cellFrame]), NSStringFromRect(snapBackRect));
			
			NSRect correctedSnapBackRect = snapBackRect;
//		correctedSnapBackRect.origin.y = NSMinY(whiteRect);
			correctedSnapBackRect.size.height = NSHeight(whiteRect);
			correctedSnapBackRect.size.width *= 1.3f;
			correctedSnapBackRect.origin.y -= 5.0f;
			correctedSnapBackRect.origin.x -= 1.5f;
			
			NSBezierPath *snapBackButton = [NSBezierPath bezierPathWithRect:correctedSnapBackRect];
			[[[[NSColor windowFrameColor] shadowWithLevel:0.2f] colorWithAlphaComponent:alphaRecording] set];
			[snapBackButton stroke];
//		NSLog(@"stroked along path of %@", NSStringFromRect(correctedSnapBackRect));

			NSGradient *gradient = nil;
			if (_mouseDown && _mouseInsideTrackingArea) {
				gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.60f alpha:alphaRecording]
														 endingColor:[NSColor colorWithCalibratedWhite:0.75f alpha:alphaRecording]];
			}
			else {
				gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.75f alpha:alphaRecording]
														 endingColor:[NSColor colorWithCalibratedWhite:0.90f alpha:alphaRecording]];
			}
			CGFloat insetAmount = -([snapBackButton lineWidth]/2.0f);
			[gradient drawInRect:NSInsetRect(correctedSnapBackRect, insetAmount, insetAmount) angle:90.0f];

			/*
		// Highlight if inside or down
			 if (mouseInsideTrackingArea)
			 {
				 [[[NSColor blackColor] colorWithAlphaComponent: alphaRecording*(mouseDown ? 0.15 : 0.1)] set];
				 [snapBackButton fill];
			 }*/
			
		// Draw snapback image
			NSImage *snapBackArrow = [[NSBundle bundleForClass: self.class] imageForResource: @"SRSnapback"];
			[snapBackArrow dissolveToPoint:correctedSnapBackRect.origin fraction:1.0f*alphaRecording];
		}
		
	// Draw border and remove badge if needed
		if (![self _isEmpty] && [self isEnabled])
		{
			NSString *removeImageName = [NSString stringWithFormat: @"SRRemoveShortcut%@", (_mouseInsideTrackingArea ? (_mouseDown ? @"Pressed" : @"Rollover") :(_mouseDown ? @"Rollover" : @""))];
			NSImage *removeImage = [[NSBundle bundleForClass: self.class] imageForResource: removeImageName];
			[removeImage dissolveToPoint:[self _removeButtonRectForFrame: cellFrame].origin fraction:alphaView];
		}
		
		
		
	// Draw text
		NSMutableParagraphStyle *mpstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[mpstyle setLineBreakMode: NSLineBreakByTruncatingTail];
		[mpstyle setAlignment: NSCenterTextAlignment];
		
		CGFloat alphaCombo = alphaView;
		CGFloat alphaRecordingText = alphaRecording;
		
		NSString *displayString;
		
		if (_isRecording)
		{
	// Only the KeyCombo should be black and in a bigger font size
			BOOL recordingOrEmpty = (isVaguelyRecording || [self _isEmpty]);
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: mpstyle, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:(recordingOrEmpty ? [NSFont labelFontSize] : [NSFont smallSystemFontSize])], NSFontAttributeName,
				[(recordingOrEmpty ? [NSColor disabledControlTextColor] : [NSColor blackColor]) colorWithAlphaComponent:alphaRecordingText], NSForegroundColorAttributeName, 
				nil];
		// Recording, but no modifier keys down
			if (![self _validModifierFlags: _recordingFlags])
			{
				if (_mouseInsideTrackingArea)
				{
				// Mouse over snapback
					displayString = SRLocalizedString(@"Use old shortcut");
				}
				else
				{
				// Mouse elsewhere
					displayString = SRLocalizedString(@"Type shortcut");
				}
			}
			else
			{
			// Display currently pressed modifier keys
				displayString = SRStringForCocoaModifierFlags(_recordingFlags);
				
			// Fall back on 'Type shortcut' if we don't have modifier flags to display; this will happen for the fn key depressed
				if (![displayString length])
				{
					displayString = SRLocalizedString(@"Type shortcut");
				}
			}
			
			NSRect textRect = cellFrame;
			textRect.origin.y -= 3.0f;
			
			[displayString drawInRect:textRect withAttributes:attributes];
		}
		
		else
		{
			// Only the KeyCombo should be black and in a bigger font size
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: mpstyle, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:([self _isEmpty] ? [NSFont labelFontSize] : [NSFont smallSystemFontSize])], NSFontAttributeName,
				[([self _isEmpty] ? [NSColor disabledControlTextColor] : [NSColor blackColor]) colorWithAlphaComponent:alphaCombo], NSForegroundColorAttributeName, 
				nil];
			
			// Not recording...
			if ([self _isEmpty])
			{
				displayString = SRLocalizedString(@"Click to record shortcut");
			}
			else
			{
				displayString = [self keyComboString];
			}
			
			NSRect textRect = cellFrame;
			textRect.origin.y = NSMinY(textRect)-3.0f;
			
			[displayString drawInRect:textRect withAttributes:attributes];
		}
		
		[[NSGraphicsContext currentContext] restoreGraphicsState];
		
    // draw a focus ring...?
		
		if ([self showsFirstResponder])
		{
			[NSGraphicsContext saveGraphicsState];
			NSSetFocusRingStyle(NSFocusRingOnly);
			radius = NSHeight(cellFrame) / 2.0f;
			[[NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:radius yRadius:radius] fill];
			[NSGraphicsContext restoreGraphicsState];
		}
		
	
}

#pragma mark *** Mouse Tracking ***

- (void)resetTrackingRects
{	
	SRRecorderControl *controlView = (SRRecorderControl *)self.controlView;
	NSRect cellFrame = [controlView bounds];
	NSPoint mouseLocation = [controlView convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];

	// Remove existing tracking rects
	if (_removeTrackingRectTag != 0)
		[controlView removeTrackingRect: _removeTrackingRectTag];
	if (_snapbackTrackingRectTag != 0)
		[controlView removeTrackingRect: _snapbackTrackingRectTag];
	
	// No tracking when disabled
	if (!self.isEnabled)
		return;
	
	// We're either in recording or normal display mode
	if (!_isRecording) {
		// Create and register tracking rect for the remove badge if shortcut is not empty
		NSRect removeButtonRect = [self _removeButtonRectForFrame: cellFrame];
		BOOL mouseInside = [controlView mouse:mouseLocation inRect:removeButtonRect];
		
		_removeTrackingRectTag = [controlView addTrackingRect:removeButtonRect owner:self userData:nil assumeInside:mouseInside];
		_mouseInsideTrackingArea = mouseInside;
	}
	else {
		// Create and register tracking rect for the snapback badge if we're in recording mode
		NSRect snapbackRect = [self _snapbackRectForFrame: cellFrame];
		BOOL mouseInside = [controlView mouse:mouseLocation inRect:snapbackRect];
		
		_snapbackTrackingRectTag = [controlView addTrackingRect:snapbackRect owner:self userData:nil assumeInside:mouseInside];	
		_mouseInsideTrackingArea = mouseInside;
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	NSView *view = self.controlView;

	if ([[view window] isKeyWindow] || [view acceptsFirstMouse: theEvent]) {
		_mouseInsideTrackingArea = YES;
		[view display];
	}
}

- (void)mouseExited:(NSEvent*)theEvent
{
	NSView *view = self.controlView;
	
	if ([[view window] isKeyWindow] || [view acceptsFirstMouse: theEvent]) {
		_mouseInsideTrackingArea = NO;
		[view display];
	}
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(SRRecorderControl *)controlView untilMouseUp:(BOOL)flag
{		
	NSEvent *currentEvent = theEvent;
	NSPoint mouseLocation;
	
	NSRect trackingRect = (_isRecording ? [self _snapbackRectForFrame: cellFrame] : [self _removeButtonRectForFrame: cellFrame]);
	NSRect leftRect = cellFrame;

	// Determine the area without any badge
	if (!NSEqualRects(trackingRect,NSZeroRect)) leftRect.size.width -= NSWidth(trackingRect) + 4;
		
	do {
        mouseLocation = [controlView convertPoint: [currentEvent locationInWindow] fromView:nil];
		
		switch ([currentEvent type]) {
			case NSLeftMouseDown: {
				// Check if mouse is over remove/snapback image
				if ([controlView mouse:mouseLocation inRect:trackingRect]) {
					_mouseDown = YES;
					[controlView setNeedsDisplayInRect: cellFrame];
				}
				
				break;
			}
				
			case NSLeftMouseDragged: {				
				// Recheck if mouse is still over the image while dragging 
				_mouseInsideTrackingArea = [controlView mouse:mouseLocation inRect:trackingRect];
				[controlView setNeedsDisplayInRect: cellFrame];
				
				break;
			}
			
			default: {// NSLeftMouseUp
				_mouseDown = NO;
				_mouseInsideTrackingArea = [controlView mouse:mouseLocation inRect:trackingRect];

				if (_mouseInsideTrackingArea) {
					if (_isRecording) {
						// Mouse was over snapback, just redraw
                        [self _endRecording];
					}
					else {
						// Mouse was over the remove image, reset all
						[self setKeyCombo: SRMakeKeyCombo(ShortcutRecorderEmptyCode, ShortcutRecorderEmptyFlags)];
					}
				}
				else if ([controlView mouse:mouseLocation inRect:leftRect] && !_isRecording) {
					if (self.isEnabled)
                        [self _startRecording];
				}
				
				// Any click inside will make us firstResponder
				if ([self isEnabled])
					[[controlView window] makeFirstResponder: controlView];

				// Reset tracking rects and redisplay
				[self resetTrackingRects];
				[controlView setNeedsDisplayInRect: cellFrame];
				
				return YES;
			}
		}
		
    } while ((currentEvent = [[controlView window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]));
	
    return YES;
}


#pragma mark *** Responder Control ***

- (BOOL)becomeFirstResponder;
{
    // reset tracking rects and redisplay
    [self resetTrackingRects];
    [self.controlView setNeedsDisplay: YES];
    
    return YES;
}

- (BOOL)resignFirstResponder;
{
	if (_isRecording)
		[self _endRecording];
    
    [self resetTrackingRects];
    [self.controlView setNeedsDisplay: YES];
	
    return YES;
}


#pragma mark *** Key Combination Control ***

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{	
	NSUInteger flags = [self _filteredCocoaFlags: theEvent.modifierFlags];
	BOOL snapback = SRIsCancelKey(theEvent.keyCode);
	
	// Snapback key shouldn't interfer with required flags!
	BOOL modifiersValid = [self _validModifierFlags:(snapback) ? theEvent.modifierFlags : flags];
    
	
    // Special case for the space key when we aren't recording...
    if (!_isRecording && [[theEvent characters] isEqualToString:@" "]) {
        [self _startRecording];
        return YES;
    }
	
	// Do something as long as we're in recording mode and a modifier key or cancel key is pressed
	if (_isRecording && (modifiersValid || snapback)) {
		if (!snapback || modifiersValid) {
			BOOL goAhead = YES;
			
			// Special case: if a snapback key has been entered AND modifiers are deemed valid...
			if (snapback && modifiersValid) {
				// ...AND we're set to allow plain keys
				if (allowsBareKeys) {
					// ...AND modifiers are empty, or empty save for the Function key
					// (needed, since forward delete is fn+delete on laptops)
					if (flags == ShortcutRecorderEmptyFlags || flags == (ShortcutRecorderEmptyFlags | NSFunctionKeyMask)) {
						// ...check for behavior in recordsEscapeKey.
						if (!recordsEscapeKey) {
							goAhead = NO;
						}
					}
				}
			}
			
			if (goAhead) {
				
				NSString *character = [[theEvent charactersIgnoringModifiers] uppercaseString];
				
			// accents like "¬¥" or "`" will be ignored since we don't get a keycode
				if ([character length]) {
					NSError *error = nil;
					
				// Check if key combination is already used or not allowed by the delegate
					if ([validator isKeyCode:[theEvent keyCode] 
								andFlagsTaken:[self _filteredCocoaToCarbonFlags:flags]
										error:&error]) {
						// display the error...
						NSAlert *alert = [NSAlert alertWithMessageText:error.localizedDescription defaultButton:[error.localizedRecoveryOptions objectAtIndex: 0] alternateButton:nil otherButton:nil informativeTextWithFormat:(error.localizedFailureReason) ?: @""];
						[alert setAlertStyle:NSCriticalAlertStyle];
						[alert runModal];
						
					// Recheck pressed modifier keys
						[self flagsChanged: [NSApp currentEvent]];
						
						return YES;
					} else {
					// All ok, set new combination
						keyCombo.flags = flags;
						keyCombo.code = [theEvent keyCode];
						
					// Notify delegate
						if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
							[delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
						
					// Save if needed
					}
				} else {
				// invalid character
					NSBeep();
				}
			}
		}
		
		// reset values and redisplay
		_recordingFlags = ShortcutRecorderEmptyFlags;
        
        [self _endRecording];
		
		[self resetTrackingRects];
		[self.controlView setNeedsDisplay: YES];
		
		return YES;
	} else {
		//Start recording when the spacebar is pressed while the control is first responder
		if (([[self.controlView window] firstResponder] == self.controlView) &&
			theEvent.keyCode == kSRKeysSpace &&
			([self isEnabled]))
		{
			[self _startRecording];
		}
	}
	
	return NO;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	if (_isRecording) {
		_recordingFlags = [self _filteredCocoaFlags: [theEvent modifierFlags]];
		[self.controlView setNeedsDisplay: YES];
	}
}

#pragma mark -

- (void)setAllowedModifierFlags:(NSUInteger)flags
{
	allowedModifierFlags = flags;
	
	// filter new flags and change keycombo if not recording
	if (_isRecording)
	{
		_recordingFlags = [self _filteredCocoaFlags: [[NSApp currentEvent] modifierFlags]];;
	}
	else
	{
		NSUInteger originalFlags = keyCombo.flags;
		keyCombo.flags = [self _filteredCocoaFlags: keyCombo.flags];
		
		if (keyCombo.flags != originalFlags && keyCombo.code > ShortcutRecorderEmptyCode)
		{
			// Notify delegate if keyCombo changed
			if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
				[delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
		}
	}
	
	[self.controlView setNeedsDisplay: YES];
}

- (void)setAllowsBareKeys:(BOOL)nAllowsBareKeys
{
	allowsBareKeys = nAllowsBareKeys;
	if (!allowsBareKeys)
		recordsEscapeKey = NO;
}

- (void)setRecordsEscapeKey:(BOOL)nRecordsEscapeKey
{
	recordsEscapeKey = nRecordsEscapeKey;
	if (recordsEscapeKey)
		allowsBareKeys = YES;
}

- (void)setRequiredModifierFlags:(NSUInteger)flags
{
	requiredModifierFlags = flags;
	
	// filter new flags and change keycombo if not recording
	if (_isRecording)
	{
		_recordingFlags = [self _filteredCocoaFlags: [[NSApp currentEvent] modifierFlags]];
	}
	else
	{
		NSUInteger originalFlags = keyCombo.flags;
		keyCombo.flags = [self _filteredCocoaFlags: keyCombo.flags];
		
		if (keyCombo.flags != originalFlags && keyCombo.code > ShortcutRecorderEmptyCode)
		{
			// Notify delegate if keyCombo changed
			if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
				[delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
		}
	}
	
	[self.controlView setNeedsDisplay: YES];
}

- (void)setKeyCombo:(KeyCombo)aKeyCombo
{
	keyCombo = aKeyCombo;
	keyCombo.flags = [self _filteredCocoaFlags: aKeyCombo.flags];

	// Notify delegate
	if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
		[delegate shortcutRecorderCell:self keyComboDidChange:keyCombo];
	
	[self.controlView setNeedsDisplay: YES];
}

#pragma mark -

- (NSString *)keyComboString
{
	if ([self _isEmpty]) return nil;
	
	return [NSString stringWithFormat: @"%@%@",
        SRStringForCocoaModifierFlags(keyCombo.flags),
        SRStringForKeyCode(keyCombo.code)];
}

- (NSString *)characters
{
	return SRStringForKeyCode(keyCombo.code);
}

- (NSString *)charactersIgnoringModifiers
{
	return SRCharacterForKeyCodeAndCocoaFlags(keyCombo.code, keyCombo.flags);
}


#pragma mark - Private

- (void)_privateInit
{
    // init the validator object...
    validator = [[SRValidator alloc] initWithDelegate: self];
    
	// Allow all modifier keys by default, nothing is required
	allowedModifierFlags = ShortcutRecorderAllFlags;
	requiredModifierFlags = ShortcutRecorderEmptyFlags;
	_recordingFlags = ShortcutRecorderEmptyFlags;
	
	// Create clean KeyCombo
	keyCombo.flags = ShortcutRecorderEmptyFlags;
	keyCombo.code = ShortcutRecorderEmptyCode;
		
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(_createGradient) name:NSSystemColorsDidChangeNotification object:nil]; // recreate gradient if needed
	[self _createGradient];
}

- (void)_createGradient
{
	NSColor *gradientStartColor = [[[NSColor alternateSelectedControlColor] shadowWithLevel: 0.2f] colorWithAlphaComponent: 0.9f];
	NSColor *gradientEndColor = [[[NSColor alternateSelectedControlColor] highlightWithLevel: 0.2f] colorWithAlphaComponent: 0.9f];
	
	recordingGradient = [[NSGradient alloc] initWithStartingColor:gradientStartColor endingColor:gradientEndColor];
}

- (void)_startRecording;
{
    // Jump into recording mode if mouse was inside the control but not over any image
    _isRecording = YES;
    
    // Reset recording flags and determine which are required
    _recordingFlags = [self _filteredCocoaFlags: ShortcutRecorderEmptyFlags];
    
	[self.controlView setNeedsDisplay:YES];
	
    // invalidate the focus ring rect...
    NSView *controlView = self.controlView;
    [controlView setKeyboardFocusRingNeedsDisplayInRect:[controlView bounds]];

    if (canCaptureGlobalHotKeys)
		hotKeyModeToken = PushSymbolicHotKeyMode(kHIHotKeyModeAllDisabled);
}

- (void)_endRecording;
{
    _isRecording = NO;

	[self.controlView setNeedsDisplay:YES];
	
    // invalidate the focus ring rect...
    NSView *controlView = self.controlView;
    [controlView setKeyboardFocusRingNeedsDisplayInRect:[controlView bounds]];
	
	if (canCaptureGlobalHotKeys) 
		PopSymbolicHotKeyMode(hotKeyModeToken);
}


#pragma mark *** Drawing Helpers ***

- (NSRect)_removeButtonRectForFrame:(NSRect)cellFrame
{	
	if ([self _isEmpty] || ![self isEnabled]) return NSZeroRect;
	
	NSRect removeButtonRect;
	NSImage *removeImage = [[NSBundle bundleForClass: self.class] imageForResource: @"SRRemoveShortcut"];
	
	removeButtonRect.origin = NSMakePoint(NSMaxX(cellFrame) - [removeImage size].width - 4, (NSMaxY(cellFrame) - [removeImage size].height)/2);
	removeButtonRect.size = [removeImage size];

	return removeButtonRect;
}

- (NSRect)_snapbackRectForFrame:(NSRect)cellFrame
{
	NSRect snapbackRect;
	NSImage *snapbackImage = [[NSBundle bundleForClass: self.class] imageForResource: @"SRSnapback"];
	
	snapbackRect.origin = NSMakePoint(NSMaxX(cellFrame) - [snapbackImage size].width - 2, (NSMaxY(cellFrame) - [snapbackImage size].height)/2 + 1);
	snapbackRect.size = [snapbackImage size];

	return snapbackRect;
}

#pragma mark *** Filters ***

- (NSUInteger)_filteredCocoaFlags:(NSUInteger)flags
{
	return ((flags & allowedModifierFlags) | requiredModifierFlags);
}

- (BOOL)_validModifierFlags:(NSUInteger)flags
{
	return (allowsBareKeys ? YES :(((flags & NSCommandKeyMask) || (flags & NSAlternateKeyMask) || (flags & NSControlKeyMask) || (flags & NSShiftKeyMask) || (flags & NSFunctionKeyMask)) ? YES : NO));	
}

#pragma mark -

- (NSUInteger)_filteredCocoaToCarbonFlags:(NSUInteger)cocoaFlags
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	NSUInteger filteredFlags = [self _filteredCocoaFlags: cocoaFlags];
	
	if (filteredFlags & NSCommandKeyMask) carbonFlags |= cmdKey;
	if (filteredFlags & NSAlternateKeyMask) carbonFlags |= optionKey;
	if (filteredFlags & NSControlKeyMask) carbonFlags |= controlKey;
	if (filteredFlags & NSShiftKeyMask) carbonFlags |= shiftKey;
	
	// I couldn't find out the equivalent constant in Carbon, but apparently it must use the same one as Cocoa. -AK
	if (filteredFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;
	
	return carbonFlags;
}

#pragma mark *** Internal Check ***

- (BOOL)_isEmpty
{
	return (![self _validModifierFlags: keyCombo.flags] || !SRStringForKeyCode(keyCombo.code));
}

#pragma mark - Delegate forward

- (BOOL)shortcutValidator:(SRValidator *)validator isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;
{
    if ([delegate respondsToSelector:@selector(shortcutRecorderCell:isKeyCode:andFlagsTaken:reason:)])
        return [delegate shortcutRecorderCell:self isKeyCode:keyCode andFlagsTaken:flags reason:aReason];
    else
		return NO;
}

@end