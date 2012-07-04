//
//  NSMenuItem+SRConfiguration.h
//  ShortcutRecorder
//
//  Created by Max Seelemann on 04.07.12.
//
//

#import <ShortcutRecorder/SRCommon.h>

@interface NSMenuItem (SRConfiguration)

/*!
 @abstract Sets the menu items key evivalent to the passed key combo.
 */
- (void)configureWithKeyCombo:(SRKeyCombo)keyCombo;

@end
