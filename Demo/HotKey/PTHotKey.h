//
//  PTHotKey.h
//  Protein
//
//  Created by Quentin Carnicelli on Sat Aug 02 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
//
//  Contributors:
// 		Andy Kim

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import "PTKeyCombo.h"

@interface PTHotKey : NSObject
{
	NSString		*mIdentifier;
	NSString		*mName;
	PTKeyCombo		*mKeyCombo;
	id				mTarget;
	SEL				mAction;

	NSUInteger		mCarbonHotKeyID;
	EventHotKeyRef	mCarbonEventHotKeyRef;
}

- (id)initWithIdentifier:(id)identifier keyCombo:(PTKeyCombo *)combo;
- (id)init;

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *name;

@property(nonatomic, strong) PTKeyCombo *keyCombo;

@property(nonatomic, weak) id target;
@property(nonatomic, assign) SEL action;
- (void)invoke;

@property(nonatomic, assign) NSUInteger carbonHotKeyID;
@property(nonatomic, assign) EventHotKeyRef carbonEventHotKeyRef;

@end
