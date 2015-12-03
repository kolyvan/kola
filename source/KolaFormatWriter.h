//
//  KolaFormatWriter.h
//  KolaFormat
//
//  Created by Kolyvan on 02.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KolaFormatWriter : NSObject

+ (NSString *) stringWithDictionary:(NSDictionary *)dict
                              funcs:(NSArray *)funcs;

+ (NSString *)escapeString:(NSString *)s;

@end
