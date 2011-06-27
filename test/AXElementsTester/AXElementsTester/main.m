//
//  main.m
//  AXElementsTester
//
//  Created by Mark Rada on 11-06-26.
//  Copyright 2011 Marketcircle Incorporated. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
  return macruby_main("rb_main.rb", argc, argv);
}
