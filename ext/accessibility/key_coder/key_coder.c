/*
 *  key_coder.c
 *  KeyCoder
 *
 *  Created by Mark Rada on 11-07-27.
 *  Copyright 2011 Marketcircle Incorporated. All rights reserved.
 */


#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>
#include "ruby.h"

static VALUE
rb_keycoder_dynamic_mapping()
{

  VALUE map = rb_hash_new();

#ifdef NOT_MACRUBY
  @autoreleasepool {
#endif

  TISInputSourceRef keyboard = TISCopyCurrentKeyboardLayoutInputSource();
  CFDataRef layout_data = (CFDataRef)TISGetInputSourceProperty(keyboard, kTISPropertyUnicodeKeyLayoutData);
  const UCKeyboardLayout* layout = (const UCKeyboardLayout*)CFDataGetBytePtr(layout_data);

  void (^key_coder)(int) = ^(int key_code) {
    UniChar      string[255];
    UniCharCount string_length = 0;
    UInt32       dead_key_state = 0;
    UCKeyTranslate(
                   layout,
		   key_code,
		   kUCKeyActionDown,
		   0,
		   LMGetKbdType(),  // kb type
		   0,               // OptionBits keyTranslateOptions,
		   &dead_key_state,
		   255,
		   &string_length,
		   string
		  );

    NSString* nsstring = [NSString stringWithCharacters:string length:string_length];
    rb_hash_aset(map, rb_str_new_cstr([nsstring UTF8String]), INT2FIX(key_code));
  };

  // skip 65-92 since they are hard coded and do not change
  for (int key_code = 0; key_code < 65; key_code++)
    key_coder(key_code);
  for (int key_code = 93; key_code < 127; key_code++)
    key_coder(key_code);

#ifdef NOT_MACRUBY
  CFRelease(keyboard);
  }; // Close the autorelease pool
#else
  CFMakeCollectable(keyboard);
#endif

  return map;
}


static VALUE
rb_keycoder_post_event(VALUE self, VALUE event)
{
  VALUE code  = rb_ary_entry(event, 0);
  VALUE state = rb_ary_entry(event, 1);

  CGEventRef event_ref = CGEventCreateKeyboardEvent(NULL, FIX2LONG(code), state);
  CGEventPost(kCGHIDEventTap, event_ref);

  usleep(9000);
  return Qtrue;
}


void
Init_key_coder()
{
  VALUE rb_cKeyCoder = rb_define_class("KeyCoder", rb_cObject);
  rb_define_singleton_method(rb_cKeyCoder, "dynamic_mapping", rb_keycoder_dynamic_mapping, 0);
  rb_define_singleton_method(rb_cKeyCoder, "post_event", rb_keycoder_post_event, 1);
}
