//
//  KolaFormatWriter.m
//  KolaFormat
//
//  Created by Kolyvan on 02.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import "KolaFormatWriter.h"

@implementation KolaFormatWriter

+ (NSString *) stringWithDictionary:(NSDictionary *)dict
                              funcs:(NSDictionary *)funcs
{
    if (!dict.count) {
        return @"";
    }
    
    NSMutableString *ms = [NSMutableString string];
    [self printDictionary:dict funcs:funcs toString:ms level:0];
    return [ms copy];
}

+ (void) printDictionary:(NSDictionary *)dict
                   funcs:(NSDictionary *)funcs
                toString:(NSMutableString *)ms
                   level:(NSUInteger)level
{
    BOOL oneline = NO;
    
    if (level) {
        
        oneline = [self hasOnlySimpleObjects:dict.allValues];
        [self printOpenBracket:@"{" toString:ms oneline:oneline];
    }
    
    __block NSUInteger counter = 0;
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id key,
                                              id val,
                                              BOOL *stop)
     {
         NSString *sKey = [key description];
         if (sKey.length) {
             
             if (oneline && counter) {
                 [ms appendString:@" "];
             }
             
             if (oneline) {
                 
                 [ms appendString:sKey];
                 
             } else if (!level) {
             
                 [ms appendString:@"\n"];
                 [ms appendString:sKey];
                 
             } else {
                 
                 [self printPad:ms level:level];
                 [ms appendString:sKey];
             }
             
             [ms appendString:@" "];
             
             if (![self printValue:val funcs:funcs toString:ms level:level + 2]) {
                 [ms appendString:@"_"];
             }
             
             counter += 1;
         }
     }];

    if (level) {
        [self printClosedBracket:@"}" toString:ms level:level-2 oneline:oneline];
    }
}

+ (void) printArray:(NSArray *)array
              funcs:(NSDictionary *)funcs
           toString:(NSMutableString *)ms
              level:(NSUInteger)level
{
    const BOOL oneline = [self hasOnlySimpleObjects:array];
    [self printOpenBracket:@"[" toString:ms oneline:oneline];
    
    NSUInteger counter = 0;
    for (id val in array) {
        
        if (oneline && counter) {
            [ms appendString:@" "];
        }
        
        if (!oneline) {
            [self printPad:ms level:level];
        }
        
        if (![self printValue:val funcs:funcs toString:ms level:level+2]) {
            [ms appendString:@"_"];
        }
        
        counter += 1;
    }
    
    [self printClosedBracket:@"]" toString:ms level:level-2 oneline:oneline];
}

+ (BOOL) printValue:(id)val
              funcs:(NSDictionary *)funcs
           toString:(NSMutableString *)ms
              level:(NSUInteger)level
{
    if ([val isKindOfClass:[NSString class]]) {
        
        [ms appendFormat:@"\"%@\"", [self escapeString:val]];
        return YES;
        
    } else if ([val isKindOfClass:[NSNumber class]]) {
        
        [ms appendFormat:@"%@", val];
        return YES;
        
    } else if ([val isKindOfClass:[NSArray class]]) {
        
        [self printArray:val funcs:funcs toString:ms level:level];
        return YES;
        
    } else if ([val isKindOfClass:[NSDictionary class]]) {
        
        [self printDictionary:val funcs:funcs toString:ms level:level];
        return YES;
        
    } else {
        
        id p;
        if (funcs) {
            id(^func)(id) = funcs[[val class]];
            if (func) {
                p = func(val);
            }
        }
        
        if (p) {
            return [self printValue:val funcs:nil toString:ms level:level];
        }
    }

    return NO;
}

+ (void) printPad:(NSMutableString *)ms
            level:(NSUInteger)level
{
    if (![ms hasSuffix:@"\n"]) {
        [ms appendString:@"\n"];
    }
    [ms appendFormat:@"%*c", (int)level, ' '];
}

+ (void) printOpenBracket:(NSString *)bracket
                 toString:(NSMutableString *)ms
                  oneline:(BOOL)oneline
{
    [ms appendString:bracket];
    if (oneline) {
        [ms appendString:@" "];
    } else {
        [ms appendString:@"\n"];
    }
}

+ (void) printClosedBracket:(NSString *)bracket
                   toString:(NSMutableString *)ms
                      level:(NSUInteger)level
                    oneline:(BOOL)oneline
{
    if ([ms hasSuffix:@"\n"]) {
        [ms appendFormat:@"%*c", (int)level, ' '];
    } else if (oneline) {
        [ms appendString:@" "];
    } else {
        [ms appendString:@"\n"];
        [ms appendFormat:@"%*c", (int)level, ' '];
    }
    
    [ms appendString:bracket];
    [ms appendString:@"\n"];
}

+ (BOOL) hasOnlySimpleObjects:(NSArray *)array
{
    for (id val in array) {
        if (![val isKindOfClass:[NSString class]] &&
            ![val isKindOfClass:[NSNumber class]])
        {
            return NO;
            break;
        }
    }
    return YES;
}

+ (NSString *)escapeString:(NSString *)s
{
    if (!s.length) {
        return s;
    }
    
    static NSCharacterSet *charset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        charset = [NSCharacterSet characterSetWithCharactersInString:@"\"\\\a\b\t\n\f\v"];
    });

    if ([s rangeOfCharacterFromSet:charset].location == NSNotFound) {
        return s;
    }
    
    NSMutableString *ms = [NSMutableString stringWithCapacity:s.length];
    
    NSScanner *scanner = [NSScanner scannerWithString:s];
    scanner.charactersToBeSkipped = nil;
    
    while (!scanner.isAtEnd) {
        
        NSString *buf;
        if ([scanner scanUpToCharactersFromSet:charset intoString:&buf]) {
            [ms appendString:buf];
        }
        
        if ([scanner scanCharactersFromSet:charset intoString:&buf]) {
            
            for (NSUInteger i = 0; i < buf.length; ++i) {
                
                NSString *s = [buf substringWithRange:NSMakeRange(i, 1)];

                if ([s isEqualToString:@"\""]) {
                    [ms appendString:@"\\\""];
                } else if ([s isEqualToString:@"\\"]) {
                    [ms appendString:@"\\\\"];
                } else if ([s isEqualToString:@"\a"]) {
                    [ms appendString:@"\\a"];
                } else if ([s isEqualToString:@"\b"]) {
                    [ms appendString:@"\\b"];
                } else if ([s isEqualToString:@"\t"]) {
                    [ms appendString:@"\\t"];
                } else if ([s isEqualToString:@"\n"]) {
                    [ms appendString:@"\\n"];
                } else if ([s isEqualToString:@"\f"]) {
                    [ms appendString:@"\\f"];
                } else if ([s isEqualToString:@"\v"]) {
                    [ms appendString:@"\\v"];
                }
            }
        }
    }
    
    return [ms copy];
}

@end
