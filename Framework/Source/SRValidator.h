//
//  SRValidator.h
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

@protocol SRValidatorDelegate;


@interface SRValidator : NSObject

- (id)initWithDelegate:(id <SRValidatorDelegate>)theDelegate;

- (BOOL)isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags error:(NSError **)error;
- (BOOL)isKeyCode:(NSInteger)keyCode andFlags:(NSUInteger)flags takenInMenu:(NSMenu *)menu error:(NSError **)error;

@property(nonatomic, weak) id <SRValidatorDelegate> delegate;

@end


@protocol SRValidatorDelegate <NSObject>

- (BOOL)shortcutValidator:(SRValidator *)validator isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;

@end
