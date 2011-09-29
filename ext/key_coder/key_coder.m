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
#include "ruby/ruby.h"

/*
 * @note Static keycode reference at
 *       /System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/Events.h
 *
 * Map of characters to key codes.
 *
 * @return [Hash{String=>Fixnum}]
 */
static NSMutableDictionary* mAX_keycode_map;

static VALUE mAX;

/*
 * Helper method to create the keycode mapping at runtime.
 */
static void mAX_initialize_keycode_map() {

  TISInputSourceRef currentKeyboard      = TISCopyCurrentKeyboardInputSource();
  CFDataRef keyboardLayoutData           = (CFDataRef)TISGetInputSourceProperty(currentKeyboard,
                                                                                kTISPropertyUnicodeKeyLayoutData);
  const UCKeyboardLayout* keyboardLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(keyboardLayoutData);
  UInt32                    deadKeyState = 0;
  UniCharCount        actualStringLength = 0;
  UniChar                        string[255];

  mAX_keycode_map = [[NSMutableDictionary alloc] initWithCapacity:255];

  for (int keyCode = 0; keyCode < 255; keyCode++) {
    UCKeyTranslate (
                    keyboardLayout,
                    keyCode,
                    kUCKeyActionDown,
                    0,
                    0, // kb type
                    0, // OptionBits keyTranslateOptions,
                    &deadKeyState,
                    255,
                    &actualStringLength,
                    string
                    );

    [mAX_keycode_map setObject:[NSNumber numberWithInt:keyCode]
                        forKey:[NSString stringWithFormat:@"%C", string[0]]];
  }

}

void Init_key_coder() {

  // TODO: Make mapping keys lazy, expose a C function to map a single
  //       character to a keycode, and define a hash in Ruby land that
  //       will use the hash callback feature to get the mapping on demand.
  //       POSSIBLE PROBLEM: How to handle alternative characters, like
  //       symbols which require holding shift first? How would we know
  //       about them?

  // Initialize the mapping and expose it as a constant in the AX module
  mAX_initialize_keycode_map();
  mAX = rb_define_module("AX");
  rb_define_const(mAX, "KEYCODE_MAP", (VALUE)mAX_keycode_map);
  // No need to expose the method right now...
  //rb_define_module_function(mAX, "initialize_keycode_map", mAX_initialize_keycode_map, 0);

}
