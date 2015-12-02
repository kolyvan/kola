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
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"kola"];
    NSString *string = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *dict; NSError *error;
    dict = [KolaFormatReader dictionaryWithString:string env:nil funcs:self.funcsTable error:&error];
    NSLog(@"%@", dict ?: error);
    
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

- (NSDictionary *) funcsTable
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
              [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
              return (id)[formatter dateFromString:val];
          }
          return (id)nil;
      },
      
      };
}

@end
