//
//  KolaFormatReader.h
//  KolaFormat
//
//  Created by Kolyvan on 01.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * __nonnull const KolaFormatReaderDomain;

enum {
    KolaFormatReaderErrorSyntax = 1,
};

@interface KolaFormatReader : NSObject

+ (nullable NSDictionary *) dictionaryWithString:(nonnull NSString *)string;

+ (nullable NSDictionary *) dictionaryWithString:(nonnull NSString *)string
                                           error:(NSError * __nullable * __nullable)error;

+ (nullable NSDictionary *) dictionaryWithString:(nonnull NSString *)string
                                             env:(nullable NSDictionary *)env
                                           funcs:(nullable NSDictionary *)funcs
                                           error:(NSError * __nullable * __nullable)error;

#pragma mark - helpers

+ (BOOL) scanNumber:(nonnull NSString *)string value:(NSNumber * __nonnull * __nullable)outVal;
+ (nonnull NSRegularExpression *) isNumberRegex;
+ (nonnull NSRegularExpression *) isIntegerRegex;
+ (nonnull NSRegularExpression *) isHexIntRegex;
+ (nullable NSString *) unescapeString:(nullable NSString *)s;

@end
