//
//  main.m
//  KeyCoder
//
//  Created by Mark Rada on 11-07-27.
//  Copyright 2011 Marketcircle Incorporated. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

int main (int argc, const char * argv[])
{

    TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource(); 
    CFDataRef uchr = (CFDataRef)TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData); 
    const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(uchr); 
    UInt32 deadKeyState = 0;
    UniCharCount actualStringLength = 0;
    UniChar string[255];
   
    NSMutableDictionary* KEYCODE_MAP = [[NSMutableDictionary alloc] initWithCapacity:255];
    
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

        [KEYCODE_MAP setObject:[NSNumber numberWithInt:keyCode]
                        forKey:[NSString stringWithFormat:@"%C", string[0]]];
    }


    NSLog(@"%@", [KEYCODE_MAP description]);
    
    return 0;
}

