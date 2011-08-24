//
//  main.m
//  Double Click
//
//  Created by Mark Rada on 11-08-24.
//  Copyright (c) 2011 Marketcircle Incorporated. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

int main (int argc, const char * argv[])
{   

    @autoreleasepool {

        sleep(10); // Quickly position mouse! Then wait for double click...
        
        CGPoint position = CGEventGetLocation(CGEventCreate(nil));
        CGEventRef event;
        
        event = CGEventCreateMouseEvent(nil, kCGEventLeftMouseDown, position, kCGMouseButtonLeft);
        CGEventSetIntegerValueField(event, kCGMouseEventClickState, 2);
        CGEventPost(kCGHIDEventTap, event);

        CGEventSetType(event, kCGEventLeftMouseUp);
        CGEventPost(kCGHIDEventTap, event);
        
        CGEventSetType(event, kCGEventLeftMouseDown);
        CGEventPost(kCGHIDEventTap, event);

        CGEventSetType(event, kCGEventLeftMouseUp);
        CGEventPost(kCGHIDEventTap, event);

        sleep(3);
        
    }

    return 0;
}
