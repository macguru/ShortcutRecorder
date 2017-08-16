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

- (BOOL)_isEmpty;
@end

#pragma mark -

@implementation SRRecorderCell

@synthesize allowsBareKeys, recordsEscapeKey, requiredModifierFlags, allowedModifierFlags, canCaptureGlobalHotKeys, delegate, shortcut;

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
		
		shortcut = [SRKeyCombo keyComboWithKeyCode:[[aDecoder decodeObjectForKey: @"keyComboCode"] shortValue]
									 keyEquivalent:nil
								  andModifierFlags:[[aDecoder decodeObjectForKey: @"keyComboFlags"] unsignedIntegerValue]];
		
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
	
	[aCoder encodeObject:[NSNumber numberWithShort: shortcut.keyCode] forKey:@"keyComboCode"];
	[aCoder encodeObject:@(shortcut.modifierFlags) forKey:@"keyComboFlags"];
	
	[aCoder encodeObject:@(allowedModifierFlags) forKey:@"allowedModifierFlags"];
	[aCoder encodeObject:@(requiredModifierFlags) forKey:@"requiredModifierFlags"];
	
	[aCoder encodeObject:@(allowsBareKeys) forKey:@"allowsBareKeys"];
	[aCoder encodeObject:@(recordsEscapeKey) forKey:@"recordsEscapeKey"];
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

	cell->shortcut = shortcut;

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
	NSRect innerFrame = NSInsetRect(cellFrame, 0.5f, 0.5f);
	NSRect textFrame = NSInsetRect(cellFrame, 3, 1);
	
	// Draw Background
	CGFloat radius = NSHeight(innerFrame) / 2;
	NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:innerFrame xRadius:radius yRadius:radius];
	
	[[NSColor colorWithCalibratedWhite:0.1 alpha:1] set];
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[backgroundPath fill];
	[backgroundPath addClip];
	
	
	// Draw snapback button
	if (_isRecording) {
		NSRect snapbackRect = [self _snapbackRectForFrame: cellFrame];
		
		// Snapback fill
		NSGradient *gradient = nil;
		if (_mouseDown && _mouseInsideTrackingArea) {
			gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.2f alpha:1]
													 endingColor:[NSColor colorWithCalibratedWhite:0.1f alpha:1]];
		}
		else {
			gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.1f alpha:1]
													 endingColor:[NSColor colorWithCalibratedWhite:0.2f alpha:1]];
		}
		
		[gradient drawInRect:NSInsetRect(snapbackRect, 0.5, 0.5) angle:90];
		
		// Draw snapback image
		NSImage *snapbackArrow = [[NSBundle bundleForClass: self.class] imageForResource: @"SRSnapback"];
		
		NSPoint point;
		point.x = NSMinX(snapbackRect) + round((NSWidth(snapbackRect) - snapbackArrow.size.width) / 2);
		point.y = NSMinY(snapbackRect) + round((NSHeight(snapbackRect) - snapbackArrow.size.height) / 2) + 1;
		[snapbackArrow drawAtPoint:point fromRect:NSMakeRect(0, 0, snapbackArrow.size.width, snapbackArrow.size.height) operation:NSCompositingOperationSourceOver fraction:1.0];
		
		// Snapback stroke
		NSBezierPath *snapbackButton = [NSBezierPath bezierPathWithRect:NSInsetRect(snapbackRect, 0.5f, 0.5f)];
		[[NSColor colorWithCalibratedWhite:0 alpha:1] set];
		[snapbackButton stroke];
		
		// Inset text rect
		textFrame.size.width = NSMinX(snapbackRect) - 2 - NSMinX(textFrame);
	}
	
	// Draw erase button
	else if (![self _isEmpty] && [self isEnabled]) {
		NSString *removeImageName = [NSString stringWithFormat: @"SRRemoveShortcut%@", (_mouseInsideTrackingArea ? (_mouseDown ? @"Pressed" : @"Rollover") : (_mouseDown ? @"Rollover" : @""))];
		
		// Draw remove image
		NSImage *removeImage = [[NSBundle bundleForClass: self.class] imageForResource: removeImageName];
		NSRect removeRect = [self _removeButtonRectForFrame: cellFrame];
		
		NSPoint point;
		point.x = NSMinX(removeRect);
		point.y = NSMinY(removeRect) + (NSHeight(removeRect) - removeImage.size.height) / 2;
		[removeImage drawAtPoint:point fromRect:NSMakeRect(0, 0, removeImage.size.width, removeImage.size.height) operation:NSCompositingOperationSourceOver fraction:1.0];
		
		// Inset text rect
		textFrame.size.width = NSMinX(removeRect) - 2 - NSMinX(textFrame);
	}
	
	
	// Display string depending on state
	NSString *displayString;
	if (_isRecording) {
		// Recording, but no valid modifier keys down
		if (![self _validModifierFlags:_recordingFlags forKeyCode:NSNotFound]) {
			displayString = SRLocalizedString((_mouseInsideTrackingArea) ? @"Use old shortcut" : @"Type shortcut");
		} else {
			// Display currently pressed modifier keys
			displayString = SRStringForCocoaModifierFlags(_recordingFlags);
			
			// Fall back on 'Type shortcut' if we don't have modifier flags to display; this will happen for the fn key depressed
			if (![displayString length])
				displayString = SRLocalizedString(@"Type shortcut");
		}
	} else {
		if ([self _isEmpty])
			displayString = SRLocalizedString(@"Click to record shortcut");
		else
			displayString = shortcut.string;
	}
	
	// Text attributes
	BOOL recordingOrEmpty = (_isRecording || [self _isEmpty]);
	
	NSMutableDictionary *attributes = [NSMutableDictionary new];
	attributes[NSFontAttributeName] = [NSFont systemFontOfSize:(recordingOrEmpty
																? [NSFont labelFontSize]
																: [NSFont systemFontSize])];
	attributes[NSForegroundColorAttributeName] = (recordingOrEmpty
												  ? [NSColor colorWithCalibratedWhite:0.5 alpha:1]
												  : [NSColor colorWithCalibratedRed:0.627 green:0.784 blue:0.843 alpha:1.000]);
	
	NSMutableParagraphStyle *pStyle = [NSMutableParagraphStyle new];
	pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
	attributes[NSParagraphStyleAttributeName] = pStyle;
	
	// Draw text
	NSRect usedTextFrame = [displayString boundingRectWithSize:textFrame.size options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
	
	usedTextFrame.origin.x = MIN(NSMidX(cellFrame)/2 + NSMidX(textFrame)/2 - NSWidth(usedTextFrame)/2,
								 NSMaxX(textFrame) - NSWidth(usedTextFrame));
	usedTextFrame.origin.y += (NSHeight(textFrame) - NSHeight(usedTextFrame)) / 2 + NSMinY(textFrame) + (recordingOrEmpty ? 0 : 1);
	
	[displayString drawWithRect:usedTextFrame options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
	
	
	// Remove clipping
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	// Draw outline
	[[NSColor colorWithCalibratedWhite:0 alpha:1] set];
	[backgroundPath stroke];
	
	
    // draw a focus ring...?
	if ([self showsFirstResponder]) {
		[NSGraphicsContext saveGraphicsState];
		NSSetFocusRingStyle(NSFocusRingOnly);
//		[backgroundPath fill];
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
			case NSEventTypeLeftMouseDown: {
				// Check if mouse is over remove/snapback image
				if ([controlView mouse:mouseLocation inRect:trackingRect]) {
					_mouseDown = YES;
					[controlView setNeedsDisplayInRect: cellFrame];
				}
				
				break;
			}
				
			case NSEventTypeLeftMouseDragged: {				
				// Recheck if mouse is still over the image while dragging 
				_mouseInsideTrackingArea = [controlView mouse:mouseLocation inRect:trackingRect];
				[controlView setNeedsDisplayInRect: cellFrame];
				
				break;
			}
			
			default: {// NSEventTypeLeftMouseUp
				_mouseDown = NO;
				_mouseInsideTrackingArea = [controlView mouse:mouseLocation inRect:trackingRect];

				if (_mouseInsideTrackingArea) {
					if (_isRecording) {
						// Mouse was over snapback, just redraw
                        [self _endRecording];
					}
					else {
						// Mouse was over the remove image, reset all
						[self setShortcut: nil];
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
		
    } while ((currentEvent = [[controlView window] nextEventMatchingMask:(NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]));
	
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
	BOOL modifiersValid = [self _validModifierFlags:(snapback ? theEvent.modifierFlags : flags) forKeyCode:theEvent.keyCode];
    
	
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
						NSAlert *alert = [NSAlert alertWithMessageText:error.localizedDescription defaultButton:(error.localizedRecoveryOptions)[0] alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", (error.localizedFailureReason) ?: @""];
						[alert setAlertStyle:NSAlertStyleCritical];
						[alert runModal];
						
					// Recheck pressed modifier keys
						[self flagsChanged: [NSApp currentEvent]];
						
						return YES;
					} else {
					// All ok, set new combination
						NSString *keyEquivalent = theEvent.charactersIgnoringModifiers.lowercaseString;
						if (![keyEquivalent rangeOfCharacterFromSet: NSCharacterSet.alphanumericCharacterSet].length)
							keyEquivalent = nil;
						
						shortcut = [SRKeyCombo keyComboWithKeyCode:theEvent.keyCode keyEquivalent:keyEquivalent andModifierFlags:flags];
						
					// Notify delegate
						if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
							[delegate shortcutRecorderCell:self keyComboDidChange:shortcut];
						
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
	
	// filter new flags and change shortcut if not recording
	if (_isRecording)
	{
		_recordingFlags = [self _filteredCocoaFlags: [[NSApp currentEvent] modifierFlags]];;
	}
	else
	{
		SRKeyCombo *fixedCombo = shortcut ? [SRKeyCombo keyComboWithKeyCode:shortcut.keyCode
															  keyEquivalent:shortcut.keyEquivalent
														   andModifierFlags:[self _filteredCocoaFlags: shortcut.modifierFlags]] : nil;
		
		if (fixedCombo && ![fixedCombo isEqual: shortcut]) {
			shortcut = fixedCombo;
			
			// Notify delegate if shortcut changed
			if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
				[delegate shortcutRecorderCell:self keyComboDidChange:shortcut];
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
	
	// filter new flags and change shortcut if not recording
	if (_isRecording)
	{
		_recordingFlags = [self _filteredCocoaFlags: [[NSApp currentEvent] modifierFlags]];
	}
	else
	{
		SRKeyCombo *fixedCombo = shortcut ? [SRKeyCombo keyComboWithKeyCode:shortcut.keyCode
															  keyEquivalent:shortcut.keyEquivalent
														   andModifierFlags:[self _filteredCocoaFlags: shortcut.modifierFlags]] : nil;
		
		if (fixedCombo && ![fixedCombo isEqual: shortcut]) {
			shortcut = fixedCombo;
			
			// Notify delegate if shortcut changed
			if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
				[delegate shortcutRecorderCell:self keyComboDidChange:shortcut];
		}
	}
	
	[self.controlView setNeedsDisplay: YES];
}

- (void)setShortcut:(SRKeyCombo *)aKeyCombo
{
	shortcut = (aKeyCombo) ? [SRKeyCombo keyComboWithKeyCode:aKeyCombo.keyCode
											   keyEquivalent:aKeyCombo.keyEquivalent
											andModifierFlags:[self _filteredCocoaFlags: aKeyCombo.modifierFlags]] : nil;
	
	// Notify delegate
	if (delegate != nil && [delegate respondsToSelector: @selector(shortcutRecorderCell:keyComboDidChange:)])
		[delegate shortcutRecorderCell:self keyComboDidChange:shortcut];
	
	[self.controlView setNeedsDisplay: YES];
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
	
	// Create clean SRKeyCombo
	shortcut = nil;
		
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
	
	NSImage *removeImage = [[NSBundle bundleForClass: self.class] imageForResource: @"SRRemoveShortcut"];
	
	NSRect removeButtonRect;
	removeButtonRect.size.width = round(removeImage.size.width * 1.3);
	removeButtonRect.size.height = NSHeight(cellFrame);
	removeButtonRect.origin.x = NSWidth(cellFrame) - removeButtonRect.size.width;
	removeButtonRect.origin.y = 0;
	
	return removeButtonRect;
}

- (NSRect)_snapbackRectForFrame:(NSRect)cellFrame
{
	NSImage *snapbackImage = [[NSBundle bundleForClass: self.class] imageForResource: @"SRSnapback"];
	
	NSRect snapbackRect;
	snapbackRect.size.width = round(snapbackImage.size.width * 1.6);
	snapbackRect.size.height = NSHeight(cellFrame);
	snapbackRect.origin.x = NSWidth(cellFrame) - snapbackRect.size.width;
	snapbackRect.origin.y = 0;

	return snapbackRect;
}

#pragma mark *** Filters ***

- (NSUInteger)_filteredCocoaFlags:(NSUInteger)flags
{
	return ((flags & allowedModifierFlags) | requiredModifierFlags);
}

- (BOOL)_validModifierFlags:(NSUInteger)flags forKeyCode:(NSInteger)keyCode
{
	if ([delegate respondsToSelector: @selector(shortcutRecorderCell:areModifierFlags:validForKeyCode:)])
		return [delegate shortcutRecorderCell:self areModifierFlags:flags validForKeyCode:keyCode];
	else
		return (allowsBareKeys ? YES :(((flags & NSEventModifierFlagCommand) || (flags & NSEventModifierFlagOption) || (flags & NSEventModifierFlagControl) || (flags & NSEventModifierFlagShift) || (flags & NSFunctionKeyMask)) ? YES : NO));
}

#pragma mark -

- (NSUInteger)_filteredCocoaToCarbonFlags:(NSUInteger)cocoaFlags
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	NSUInteger filteredFlags = [self _filteredCocoaFlags: cocoaFlags];
	
	if (filteredFlags & NSEventModifierFlagCommand) carbonFlags |= cmdKey;
	if (filteredFlags & NSEventModifierFlagOption) carbonFlags |= optionKey;
	if (filteredFlags & NSEventModifierFlagControl) carbonFlags |= controlKey;
	if (filteredFlags & NSEventModifierFlagShift) carbonFlags |= shiftKey;
	
	// I couldn't find out the equivalent constant in Carbon, but apparently it must use the same one as Cocoa. -AK
	if (filteredFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;
	
	return carbonFlags;
}

#pragma mark *** Internal Check ***

- (BOOL)_isEmpty
{
	return !shortcut;
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
