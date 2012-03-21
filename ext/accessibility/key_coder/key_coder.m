/*
 *  key_code_generator.m
 *  KeyCodeGenerator
 *
 *  Created by Mark Rada on 11-07-27.
 *  Copyright 2011 Marketcircle Incorporated. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

#ifdef NOT_MACRUBY
#import <ApplicationServices/ApplicationServices.h>
#include "ruby.h"
#endif


@interface KeyCodeGenerator : NSObject {
}

// Helper method to create the dynamic portion of the keycode mapping at runtime.
+ (id) dynamic_mapping;

@end

@implementation KeyCodeGenerator : NSObject {
}

+ (id) dynamic_mapping {

  TISInputSourceRef keyboard = TISCopyCurrentKeyboardLayoutInputSource();
  CFDataRef layout_data = (CFDataRef)TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData);
  const UCKeyboardLayout* layout = (const UCKeyboardLayout*)CFDataGetBytePtr(layout_data);


#ifdef NOT_MACRUBY
  VALUE map = rb_hash_new();
#else
  NSMutableDictionary* map = [[NSMutableDictionary alloc] initWithCapacity:99];
#endif

  void (^key_coder)(int) = ^(int key_code) {
    UniChar      string[255];
    UniCharCount string_length = 0;
    UInt32       dead_key_state = 0;
    UCKeyTranslate (
                    layout,
                    key_code,
                    kUCKeyActionDown,
                    0,
                    LMGetKbdType(), // kb type
                    0, // OptionBits keyTranslateOptions,
                    &dead_key_state,
                    255,
                    &string_length,
                    string
                    );

    @autoreleasepool {
      NSString* nsstring = [NSString stringWithCharacters:string length:string_length];
#ifdef NOT_MACRUBY
      rb_hash_aset(map, rb_str_new_cstr([nsstring UTF8String]), INT2FIX(key_code));
#else
      [map setObject:[NSNumber numberWithInt:key_code] forKey:nsstring];
#endif
    };
  };

  // skip 65 - 92 since they are hard coded and do not change
  for (int key_code = 0; key_code < 65; key_code++)
    key_coder(key_code);
  for (int key_code = 93; key_code < 127; key_code++)
    key_coder(key_code);

#ifdef NOT_MACRUBY
  CFRelease(keyboard);
#else
  CFMakeCollectable(keyboard);
#endif

  return (id)map;
}

@end


#ifdef NOT_MACRUBY
VALUE rb_keycode_generate_mapping() {
  return (VALUE)[KeyCodeGenerator dynamic_mapping];
}

VALUE rb_keycode_post_event(VALUE self, VALUE event) {
  CGEventRef event_ref = CGEventCreateKeyboardEvent(NULL, rb_ary_entry(event,0), rb_ary_entry(event,1));
  CGEventPost(kCGHIDEventTap, event_ref);
  return Qtrue;
}

void Init_key_code_generator() {
  VALUE rb_cKeyCodeGenerator = rb_define_class("KeyCodeGenerator", rb_cObject);
  rb_define_singleton_method(rb_cKeyCodeGenerator, "dynamic_mapping", rb_keycode_generate_mapping, 0);
  rb_define_singleton_method(rb_cKeyCodeGenerator, "post_event", rb_keycode_post_event, 1);
}

#else
void Init_key_code_generator() {}
#endif
