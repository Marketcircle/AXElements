/*
 *  key_coder.m
 *  KeyCoder
 *
 *  Created by Mark Rada on 11-07-27.
 *  Copyright 2011 Marketcircle Incorporated. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

@interface KeyCodeGenerator : NSObject
{}

// Helper method to create the dynamic portion of the keycode mapping at runtime.
+ (NSMutableDictionary*) dynamic_mapping;

@end

@implementation KeyCodeGenerator : NSObject
{}

+ (NSMutableDictionary*) dynamic_mapping {

  TISInputSourceRef currentKeyboard      = TISCopyCurrentKeyboardLayoutInputSource();
  CFDataRef keyboardLayoutData           = (CFDataRef)TISGetInputSourceProperty(currentKeyboard,
                                                                                kTISPropertyUnicodeKeyLayoutData);
  const UCKeyboardLayout* keyboardLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(keyboardLayoutData);
  UInt32                    deadKeyState = 0;
  UniCharCount        actualStringLength = 0;
  UniChar                        string[255];

  NSMutableDictionary* map = [[NSMutableDictionary alloc] initWithCapacity:100];

  // skip 65 - 92 since they are hard coded and do not change

  for (int keyCode = 0; keyCode < 65; keyCode++) {
    UCKeyTranslate (
                    keyboardLayout,
                    keyCode,
                    kUCKeyActionDown,
                    0,
                    LMGetKbdType(), // kb type
                    0, // OptionBits keyTranslateOptions,
                    &deadKeyState,
                    255,
                    &actualStringLength,
                    string
                    );

    [map setObject:[NSNumber numberWithInt:keyCode]
            forKey:[NSString stringWithCharacters:string length:actualStringLength]];
  }

  for (int keyCode = 93; keyCode < 127; keyCode++) {
    UCKeyTranslate (
                    keyboardLayout,
                    keyCode,
                    kUCKeyActionDown,
                    0,
                    LMGetKbdType(), // kb type
                    0, // OptionBits keyTranslateOptions,
                    &deadKeyState,
                    255,
                    &actualStringLength,
                    string
                    );

    [map setObject:[NSNumber numberWithInt:keyCode]
            forKey:[NSString stringWithCharacters:string length:actualStringLength]];
  }

  CFMakeCollectable(currentKeyboard);
  return map;

}

@end

void Init_key_coder() {
}
