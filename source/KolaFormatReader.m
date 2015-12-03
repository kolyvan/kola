//
//  KolaFormatReader.m
//  KolaFormat
//
//  Created by Kolyvan on 01.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import "KolaFormatReader.h"

NSString * const KolaFormatReaderDomain = @"com.kolyvan.kolaformat.reader";

typedef NS_ENUM(NSUInteger, KolaFormatReaderResult) {
    
    KolaFormatReaderResultGood,
    KolaFormatReaderResultError,
    KolaFormatReaderResultEmpty,
    KolaFormatReaderResultTermDict,
};

//////////

@implementation KolaFormatReader

+ (NSDictionary *) dictionaryWithString:(NSString *)string
{
    return [self dictionaryWithString:string env:nil funcs:nil error:nil];
}

+ (NSDictionary *) dictionaryWithString:(NSString *)string
                                  error:(NSError **)error
{
    return [self dictionaryWithString:string env:nil funcs:nil error:error];
}

+ (NSDictionary *) dictionaryWithString:(NSString *)string
                                    env:(NSDictionary *)env
                                  funcs:(NSDictionary *)funcs
                                  error:(NSError **)error
{
    if (!string.length) {
        return nil;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = nil;
    
    NSMutableArray *envs = [NSMutableArray array];
    if (env) {
        [envs addObject:env];
    }
    
    NSDictionary *dict;
    if (![self scanNext:scanner
                   envs:envs
                  funcs:funcs
             expectTerm:NO
                   dict:&dict
                  error:error]) {
        return nil;
    }
    return dict;
}

#pragma mark - scanners

+ (KolaFormatReaderResult) scanNext:(NSScanner *)scanner
                               envs:(NSMutableArray *)envs
                              funcs:(NSDictionary *)funcs
                                key:(NSString **)outKey
                                val:(id *)outVal
                              error:(NSError **)error
{
    NSString *key;
    if (![scanner scanUpToCharactersFromSet:self.valueSeparatorsCharset intoString:&key]) {
        if (scanner.isAtEnd) {
            return KolaFormatReaderResultEmpty;
        }
        if (error) {
            *error = [self syntaxError:NSLocalizedString(@"unexpected '%@' at: %u", nil),
                      [scanner.string substringWithRange:NSMakeRange(scanner.scanLocation, 1)],
                      (unsigned)(scanner.scanLocation)];
        }
        return KolaFormatReaderResultError;
    }
    
    if ([key hasPrefix:@"}"]) {
        if (key.length > 1) {
            scanner.scanLocation -= (key.length - 1);
        }
        return KolaFormatReaderResultTermDict;
    }
    
    const NSRange r = [key rangeOfCharacterFromSet:self.closeBracketCharset];
    if (r.location != NSNotFound) {
        if (error) {
            *error = [self syntaxError:NSLocalizedString(@"unexpected '%@' at: %u", nil),
                      [key substringWithRange:r],
                      (unsigned)(scanner.scanLocation - key.length + r.location)];
        }
        return KolaFormatReaderResultError;
    }
        
    [self skipBeforeValue:scanner];
    
    id val;
    const KolaFormatReaderResult res = [self scanNext:scanner
                                                 envs:envs
                                                funcs:funcs
                                                value:&val
                                                error:error];
    if (res == KolaFormatReaderResultGood) {
        
        *outKey = key;
        *outVal = val;
        return KolaFormatReaderResultGood;
    }
    
    if (res == KolaFormatReaderResultEmpty) {
        if (error) {
            *error = [self syntaxError:NSLocalizedString(@"expect value at: %u", nil), (unsigned)scanner.scanLocation];
        }
        return KolaFormatReaderResultError;
    }
    return res;
}

+ (KolaFormatReaderResult) scanNext:(NSScanner *)scanner
                               envs:(NSMutableArray *)envs
                              funcs:(NSDictionary *)funcs
                              value:(id *)outVal
                              error:(NSError **)error
{
    NSString *typename;
    if ([scanner scanString:@"(" intoString:nil]) {
        
        if (![self scanNext:scanner quote:@")" unescape:NO value:&typename error:error]) {
            return KolaFormatReaderResultError;
        }
    }
    
    id result;
    if ([scanner scanString:@"{" intoString:nil]) {
        
        NSDictionary *dict;
        if (![self scanNext:scanner
                       envs:envs
                      funcs:funcs
                 expectTerm:YES
                       dict:&dict
                      error:error]) {
            return KolaFormatReaderResultError;
        }
        result = dict;
        
    } else if ([scanner scanString:@"[" intoString:nil]) {
        
        NSArray *array;
        if (![self scanNext:scanner
                       envs:envs
                      funcs:funcs
                      array:&array
                      error:error]) {
            return KolaFormatReaderResultError;
        }
        result = array;
        
    } else {
        
        NSString *val;
        if (![scanner scanUpToCharactersFromSet:self.pairSeparatorsCharset intoString:&val]) {
            return KolaFormatReaderResultEmpty;
        }
        
        // process value
        
        if ([val isEqualToString:@"_"]) {
            
            result = [NSNull null];
            
        } else if ([val isEqualToString:@"true"]) {
            
            result = @YES;
            
        } else if ([val isEqualToString:@"false"]) {
            
            result = @NO;
            
        } else if ([val hasPrefix:@"'"]) {
            
            scanner.scanLocation -= (val.length - 1);
            if (![self scanNext:scanner quote:@"'" unescape:YES value:&result error:error]) {
                return KolaFormatReaderResultError;
            }
            
        } else if ([val hasPrefix:@"\""]) {
            
            scanner.scanLocation -= (val.length - 1);
            if (![self scanNext:scanner quote:@"\"" unescape:YES value:&result error:error]) {
                return KolaFormatReaderResultError;
            }
            
        } else if ([self scanNumber:val value:&result]) {
            
            // ok
            
        } else {
                        
            const NSRange r = [val rangeOfCharacterFromSet:self.closeBracketCharset];
            if (r.location != NSNotFound) {
                if (error) {
                    *error = [self syntaxError:NSLocalizedString(@"unexpected '%@' at: %u", nil),
                              [val substringWithRange:r],
                              (unsigned)(scanner.scanLocation - val.length + r.location)];
                }
                return KolaFormatReaderResultError;
            }
            
            result = val;
            
            if (!typename) {
                
                // resolve reference (reference never have typename)
                
                id tmp;
                for (NSDictionary *dict in envs.reverseObjectEnumerator) {
                    tmp = dict[val];
                    if (tmp) {
                        break;
                    }
                }
                
                if (tmp) {
                    result = tmp;
                } else {
#if DEBUG
                    NSLog(@"unresolved reference: '%@' at: %u", val, (unsigned)(scanner.scanLocation - val.length));
#endif
                }
            }
        }
    }

    if (typename) {
        result = [self castValue:result typename:typename funcs:funcs];
    }
    
    *outVal = result;
    return KolaFormatReaderResultGood;
}

+ (BOOL) scanNext:(NSScanner *)scanner
             envs:(NSMutableArray *)envs
            funcs:(NSDictionary *)funcs
       expectTerm:(BOOL)expectTerm
             dict:(NSDictionary **)outDict
            error:(NSError **)error
{
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    [envs addObject:md];
    
    while (1) {
        
        [self skipBeforeKey:scanner];
        
        NSString *key = nil;
        id val = nil;
        
        const KolaFormatReaderResult res = [self scanNext:scanner
                                                     envs:envs
                                                    funcs:funcs
                                                      key:&key
                                                      val:&val
                                                    error:error];
        if (res == KolaFormatReaderResultError) {
            
            return NO;
            
        } else if (res == KolaFormatReaderResultGood) {
            
            NSAssert(key, @"key must not be nil");
            NSAssert(val, @"val must not be nil");
            
#if DEBUG
            if (md[key]) {
                NSLog(@"key '%@' already exist, redefined at: %u", key, (unsigned)scanner.scanLocation);
            }
#endif
            
            md[key] = val;
            
        } else if (res == KolaFormatReaderResultTermDict) {
        
            if (expectTerm) {
                break;
            } else {
                if (error) {
                    const NSUInteger scanLoc = scanner.scanLocation - 1;
                    *error = [self syntaxError:NSLocalizedString(@"unexpected '%@' at: %u", nil), @"}", (unsigned)scanLoc];
                }
                return NO;
            }
            
        } else if (res == KolaFormatReaderResultEmpty) {

            if (expectTerm) {
                if (error) {
                    const NSUInteger scanLoc = scanner.scanLocation - 1;
                    *error = [self syntaxError:NSLocalizedString(@"expect '%@' at: %u", nil), @"}", (unsigned)scanLoc];
                }
                return NO;
            } else {
                break;
            }
        }
        
        if (scanner.isAtEnd) {

            if (expectTerm) {
                if (error) {
                    const NSUInteger scanLoc = scanner.scanLocation - 1;
                    *error = [self syntaxError:NSLocalizedString(@"expect '%@' at: %u", nil), @"}", (unsigned)scanLoc];
                }
                return NO;
            } else {
                break;
            }
        }
    }
    
    [envs removeLastObject];
    *outDict = [md copy];
    
    return YES;
}

+ (BOOL) scanNext:(NSScanner *)scanner
             envs:(NSMutableArray *)envs
            funcs:(NSDictionary *)funcs
            array:(NSArray **)outArray
            error:(NSError **)error
{
    NSMutableArray *ma = [NSMutableArray array];
    
    while (1) {
        
        [self skipWhites:scanner];
        
        id val = nil;
        const KolaFormatReaderResult res = [self scanNext:scanner
                                                     envs:envs
                                                    funcs:funcs
                                                    value:&val
                                                    error:error];
        if (res == KolaFormatReaderResultError) {
            
            return NO;
            
        } else if (res == KolaFormatReaderResultGood) {
            
            NSAssert(val, @"val must not be nil");
            [ma addObject:val];
            
            [self skipBeforeKey:scanner]; // this need to skip an optional comma
            
        } else if (res == KolaFormatReaderResultEmpty) {
            
            [self skipBeforeKey:scanner]; // this need to skip an optional comma
            
            if ([scanner scanString:@"]" intoString:nil]) {
                break;
            }
            
            if (error) {
                const NSUInteger scanLoc = scanner.scanLocation - 1;
                *error = [self syntaxError:NSLocalizedString(@"expect '%@' at: %u", nil), @"]", (unsigned)scanLoc];
            }
            return NO;
            
        } else {
            NSAssert(NO, @"Bugcheck");
            return NO;
        }
        
        if (scanner.isAtEnd) {
            if (error) {
                const NSUInteger scanLoc = scanner.scanLocation - 1;
                *error = [self syntaxError:NSLocalizedString(@"expect '%@' at: %u", nil), @"]", (unsigned)scanLoc];
            }
            return NO;
        }
    }
    
    *outArray = [ma copy];
    
    return YES;
}

+ (BOOL) scanNext:(NSScanner *)scanner
            quote:(NSString *)quote
         unescape:(BOOL)unescape
            value:(NSString **)outVal
            error:(NSError **)error
{
    NSString *s;
    [scanner scanUpToString:quote intoString:&s];
    
    NSString *term;
    if (![scanner scanString:quote intoString:&term]) {
        if (error) {
            const NSUInteger scanLoc = scanner.scanLocation - 1;
            *error = [self syntaxError:NSLocalizedString(@"expect '%@' at: %u", nil), quote, (unsigned)scanLoc];
        }
        return NO;
    }
    
    if (s.length) {
        *outVal = unescape ? [self unescapeString:s] : s;
    } else {
        *outVal = @"";
    }
    return YES;
}

#pragma mark - whitespaces skippers

+ (void) skipNext:(NSScanner *)scanner
          charset:(NSCharacterSet *)charset
{
    while (1) {
        
        [scanner scanCharactersFromSet:charset intoString:nil];
        
        if (![scanner scanString:@"#" intoString:nil]) {
            break;
        }
        
        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
        if (scanner.isAtEnd) {
            break;
        }
    }
}

+ (void) skipWhites:(NSScanner *)scanner
{
    [self skipNext:scanner charset:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (void) skipBeforeKey:(NSScanner *)scanner
{
    static NSCharacterSet *charset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mcs = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [mcs addCharactersInString:@","];
        charset = [mcs copy];
    });
    
    [self skipNext:scanner charset:charset];
}

+ (void) skipBeforeValue:(NSScanner *)scanner
{
    static NSCharacterSet *charset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mcs = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [mcs addCharactersInString:@"="];
        charset = [mcs copy];
    });
    
    [self skipNext:scanner charset:charset];
}

#pragma mark - helpers

+ (id)castValue:(id)value
       typename:(NSString *)typename
          funcs:(NSDictionary*)funcs
{
    if (funcs.count) {
        
        id(^func)(id) = funcs[typename];
        if (func) {
            id res = func(value);
            if (res) {
                return res;
            }
        }
    }

#if DEBUG
        NSLog(@"fail cast '%@' to typename '%@'", value, typename);
#endif

    return value;
}

+ (BOOL) scanNumber:(NSString *)string
              value:(NSNumber **)outVal
{
    if ([string isEqualToString:@"0"]) {
        
        *outVal = @0;
        return YES;
        
    } else if ([string isEqualToString:@".0"] ||
               [string isEqualToString:@"0."] ||
               [string isEqualToString:@"0.0"]) {
        
        *outVal = @0.0;
        return YES;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    const NSRange strRange = {0, string.length};
    
    const NSRange r = [self.isHexIntRegex rangeOfFirstMatchInString:string
                                                            options:0
                                                              range:strRange];
    if (NSEqualRanges(r, strRange)) {
        
        unsigned val = 0;
        if ([scanner scanHexInt:&val]) {
            *outVal = @(val);
            return YES;
        }
        
    } else {
        
        const NSRange r = [self.isIntegerRegex rangeOfFirstMatchInString:string
                                                                 options:0
                                                                   range:strRange];
        if (NSEqualRanges(r, strRange)) {
            
            NSInteger val = 0;
            if ([scanner scanInteger:&val]) {
                *outVal = @(val);
                return YES;
            }
            
        } else {
            
            const NSRange r = [self.isNumberRegex rangeOfFirstMatchInString:string
                                                                    options:0
                                                                      range:strRange];
            if (NSEqualRanges(r, strRange)) {
                
                double val = 0.;
                if ([scanner scanDouble:&val]) {
                    *outVal = @(val);
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

+ (NSCharacterSet *) valueSeparatorsCharset
{
    static NSCharacterSet *charset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mcs = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [mcs addCharactersInString:@"={[(#"];
        charset = [mcs copy];
    });
    return charset;
}

+ (NSCharacterSet *) pairSeparatorsCharset
{
    static NSCharacterSet *charset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mcs = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
        [mcs addCharactersInString:@",}]#"];
        charset = [mcs copy];
    });
    return charset;
}

+ (NSCharacterSet *) closeBracketCharset
{
    static NSCharacterSet *charset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        charset = [NSCharacterSet characterSetWithCharactersInString:@"}])"];
    });
    return charset;
}

+ (NSRegularExpression *) isNumberRegex
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"-?(\\d+(\\.\\d*)?|\\d*\\.\\d+)([eE][+-]?\\d+)?";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:0
                                                            error:nil];
    });
    return regex;
}

+ (NSRegularExpression *) isIntegerRegex
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"-?\\d+";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:0
                                                            error:nil];
    });
    return regex;
}

+ (NSRegularExpression *) isHexIntRegex
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *pattern = @"0[xX][0-9a-fA-F]+";
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:0
                                                            error:nil];
    });
    return regex;
}

+ (NSError *) syntaxError:(NSString *)format, ...
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Syntax Error", nil);
    
    if (format) {
        
        va_list args;
        va_start(args, format);
        NSString *reason = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        if (reason.length) {
            userInfo[NSLocalizedFailureReasonErrorKey] = reason;
        }
    }
    
    return [NSError errorWithDomain:KolaFormatReaderDomain
                               code:KolaFormatReaderErrorSyntax
                           userInfo:[userInfo copy]];
    
}

+ (NSString *) unescapeString:(NSString *)s
{
    // unescape escaped sequences
    // https://en.wikipedia.org/wiki/Escape_character
    // https://en.wikipedia.org/wiki/Escape_sequences_in_C
    
    if (!s.length) {
        return s;
    }
    
    if ([s rangeOfString:@"\\"].location == NSNotFound) {
        return s;
    }
    
    NSMutableString *ms = [NSMutableString stringWithCapacity:s.length];
    
    NSScanner *scanner = [NSScanner scannerWithString:s];
    scanner.charactersToBeSkipped = nil;
    
    while (!scanner.isAtEnd) {
        
        NSString *s;
        if ([scanner scanUpToString:@"\\" intoString:&s]) {
            [ms appendString:s];
        }
        
        if ([scanner scanString:@"\\" intoString:nil]) {
            
            const NSUInteger scanLoc = scanner.scanLocation;
            if (scanLoc < scanner.string.length) {
                
                const unichar ch = [scanner.string characterAtIndex:scanLoc];
                switch (ch) {
                    case '\'':  [ms appendString:@"'"];  scanner.scanLocation += 1; break;
                    case '"':   [ms appendString:@"\""]; scanner.scanLocation += 1; break;
                    case '\\':  [ms appendString:@"\\"]; scanner.scanLocation += 1; break;
                    case 'n':   [ms appendString:@"\n"]; scanner.scanLocation += 1; break;
                    case 't':   [ms appendString:@"\t"]; scanner.scanLocation += 1; break;
                    case 'a':   [ms appendString:@"\a"]; scanner.scanLocation += 1; break;                        
                    case 'b':   [ms appendString:@"\b"]; scanner.scanLocation += 1; break;
                    case 'f':   [ms appendString:@"\f"]; scanner.scanLocation += 1; break;
                    case 'v':   [ms appendString:@"\v"]; scanner.scanLocation += 1; break;
                    case '?':   [ms appendString:@"\?"]; scanner.scanLocation += 1; break;
                    case '0':   [ms appendString:@"\0"]; scanner.scanLocation += 1; break;
                        
                    case 'x':   { // hex
                        
                        if (scanLoc < scanner.string.length - 2) {
                            
                            const unichar ch1 = [scanner.string characterAtIndex:scanLoc+1];
                            const unichar ch2 = [scanner.string characterAtIndex:scanLoc+2];
                            if (ch1 < 0xff && ch2 < 0xff) {
                                char buf[3] = { (char)ch1, (char)ch2, '\0' };
                                const long x = strtol(buf, 0, 16);
                                if (x > 0 && x < 0xff) {
                                    [ms appendFormat:@"%C", (unichar)x];
                                    scanner.scanLocation += 3;
                                    break;
                                }
                            }
                        }
                            
                        [ms appendString:@"\\"];
                        break;
                    };
                        
                    case 'u':   { // unicode
                        
                        if (scanLoc < scanner.string.length - 4) {
                            
                            const unichar ch1 = [scanner.string characterAtIndex:scanLoc+1];
                            const unichar ch2 = [scanner.string characterAtIndex:scanLoc+2];
                            const unichar ch3 = [scanner.string characterAtIndex:scanLoc+3];
                            const unichar ch4 = [scanner.string characterAtIndex:scanLoc+4];
                            if (ch1 < 0xff && ch2 < 0xff && ch3 < 0xff && ch4 < 0xff) {
                                char buf[5] = { (char)ch1, (char)ch2, (char)ch3, (char)ch4, '\0' };
                                const long x = strtol(buf, 0, 16);
                                if (x > 0 && x < 0xffff) {
                                    [ms appendFormat:@"%C", (unichar)x];
                                    scanner.scanLocation += 5;
                                    break;
                                }
                            }
                        }
                            
                        [ms appendString:@"\\"]; break;
                        break;
                    };

                    default:
                        [ms appendString:@"\\"];
                        break;
                }
                
            } else {
                
                [ms appendString:@"\\"];
                break;
            }
        }
    }
    
    return [ms copy];
}

@end
