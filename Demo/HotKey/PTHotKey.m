//
//  PTHotKey.m
//  Protein
//
//  Created by Quentin Carnicelli on Sat Aug 02 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
//

#import "PTHotKey.h"

#import "PTHotKeyCenter.h"
#import "PTKeyCombo.h"

#import <objc/message.h>


@implementation PTHotKey

@synthesize identifier, name, target, action, keyCombo, carbonHotKeyID, carbonEventHotKeyRef;


- (id)init
{
	return [self initWithIdentifier:nil keyCombo:nil];
}

- (id)initWithIdentifier:(id)someIdentifier keyCombo:(PTKeyCombo *)combo
{
	self = [super init];

	if (self) {
		self.identifier = someIdentifier;
		self.keyCombo = combo;
	}

	return self;
}


- (NSString *)description
{
	return [NSString stringWithFormat: @"<%@: %@, %@>", NSStringFromClass([self class]), [self identifier], [self keyCombo]];
}

- (void)setShortcut:(PTKeyCombo *)combo
{
	keyCombo = (combo) ?: [PTKeyCombo clearKeyCombo];
}

- (void)invoke
{
	(void)objc_msgSend(target, self.action, self);
}

@end
