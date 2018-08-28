//
//  ITSwitch.h
//  ITSwitch-Demo
//
//  Created by Ilija Tovilo on 2014/01/02.
//  Copyright (c) 2014 Ilija Tovilo. All rights reserved.
//  Modified by Jerry Shan on 2017/07/24.
//  This is the header file for the iOS style switch which is used within Find my EA.
//

#import <Cocoa/Cocoa.h>

/**
 *  ITSwitch is a replica of UISwitch for Mac OS X
 */
IB_DESIGNABLE
@interface ITSwitch : NSControl

/**
 *  @property checked - Gets or sets the switches state
 */
@property (nonatomic, assign) IBInspectable BOOL checked;

/**
 *  @property tintColor - Gets or sets the switches tint
 */
@property (nonatomic, strong) IBInspectable NSColor *tintColor;

/**
 *  @property disabledBorderColor - Define the switch's border color for disabled state.
 */
@property (nonatomic, strong) IBInspectable NSColor *disabledBorderColor;

@end
