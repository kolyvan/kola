//
//  AppDelegate.m
//  KolaDemo
//
//  Created by Kolyvan on 01.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <KolaFormat/KolaFormat.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
        
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [ViewController new];
    [self.window makeKeyAndVisible];
    
#if 1
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"kola"];
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"kola"];
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *dict; NSError *error;
    dict = [KolaFormatReader dictionaryWithString:string env:nil funcs:self.readFuncs error:&error];
    NSString *ts = [KolaFormatWriter stringWithDictionary:dict funcs:self.writeFuncs];
    NSLog(@"\n%@", ts);
    NSDictionary *td = [KolaFormatReader dictionaryWithString:ts env:nil funcs:self.readFuncs error:&error];
    NSLog(@"\n%d", [dict isEqualToDictionary:td]);
    //NSLog(@"\n%@", dict);
    //NSLog(@"\n%@", td);
    
#else
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"kola"];
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"kola"];
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *dict; NSError *error;
    dict = [KolaFormatReader dictionaryWithString:string env:nil funcs:self.readFuncs error:&error];
    NSLog(@"\n%@", dict ?: error);
    
#endif
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (NSDictionary *) readFuncs
{
    return
    @{
      
      @"color" : ^(id val) {
          if ([val isKindOfClass:[NSNumber class]]) {
              const NSUInteger rgb = [val unsignedIntegerValue];
              return (id)[UIColor colorWithRed:((rgb >> 16) & 0xff) / 255.
                                         green:((rgb >> 8)  & 0xff) / 255.
                                          blue:((rgb >> 0)  & 0xff) / 255.
                                         alpha:1.];
          }
          return (id)nil;
      },
      
      @"date" : ^(id val) {
          if ([val isKindOfClass:[NSString class]]) {
              NSDateFormatter* formatter = [NSDateFormatter new];
              formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZ";
              return (id)[formatter dateFromString:val];
          }
          return (id)nil;
      },
      
      @"rect" : ^(id val) {
          if ([val isKindOfClass:[NSDictionary class]]) {
              NSDictionary *dict = val;
              const float x = [[dict objectForKey:@"x"] floatValue];
              const float y = [[dict objectForKey:@"y"] floatValue];
              const float w = [[dict objectForKey:@"w"] floatValue];
              const float h = [[dict objectForKey:@"h"] floatValue];
              return (id)[NSValue valueWithCGRect:(CGRect){x, y, w, h}];
          }
          return (id)nil;
      },
      
      @"size" : ^(id val) {
          if ([val isKindOfClass:[NSArray class]]) {
              NSArray *array = val;
              const float w = [array[0] floatValue];
              const float h = [array[1] floatValue];
              return (id)[NSValue valueWithCGSize:(CGSize){w, h}];
          }
          return (id)nil;
      },
      
      };
}

- (NSArray *) writeFuncs
{
    return
    @[
      
      ^(id val, NSString **typename) {
          if ([val isKindOfClass:[UIColor class]]) {
              *typename = @"color";
              CGColorRef cgColor = ((UIColor *)val).CGColor;
              const CGFloat *components = CGColorGetComponents(cgColor);
              const CGColorSpaceModel model = CGColorSpaceGetModel(CGColorGetColorSpace(cgColor));
              int r, g, b;
              if (model == kCGColorSpaceModelMonochrome) {
                  r = g = b = components[0] * 255.;
              } else if (model == kCGColorSpaceModelRGB) {
                  r = components[0] * 255.;
                  g = components[1] * 255.;
                  b = components[2] * 255.;
              } else {
                  return (id)nil;
              }
              int rgba = (0xff000000) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff);
              return (id)[NSString stringWithFormat:@"0x%x", rgba];              
          }
          return (id)nil;
      },
      
      ^(id val, NSString **typename) {
          if ([val isKindOfClass:[NSDate class]]) {
              *typename = @"date";
              NSDateFormatter* formatter = [NSDateFormatter new];
              formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
              formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZ";
              return (id)[formatter stringFromDate:val];
          }
          return (id)nil;
      },
       
       ^(id val, NSString **typename) {
           if ([val isKindOfClass:[NSValue class]]) {
               NSValue *ns = (NSValue *)val;
               if (!strcmp(ns.objCType, @encode(CGRect))) {
                
                   *typename = @"rect";
                   CGRect rect = ns.CGRectValue;
                   return (id)@{ @"x":@(rect.origin.x),
                                 @"y":@(rect.origin.y),
                                 @"w":@(rect.size.width),
                                 @"h":@(rect.size.height)};
                   
               } else if (!strcmp(ns.objCType, @encode(CGSize))) {

                   *typename = @"size";
                   CGSize size = ns.CGSizeValue;
                   return (id)@[ @(size.width), @(size.height) ];
               }
           }
           return (id)nil;
       },
      
      ];
}

@end
