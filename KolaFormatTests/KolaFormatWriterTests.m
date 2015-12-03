//
//  KolaFormatWriterTests.m
//  KolaFormat
//
//  Created by Kolyvan on 03.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KolaFormatWriter.h"
#import "KolaFormatReader.h"

@interface KolaFormatWriterTests : XCTestCase

@end

@implementation KolaFormatWriterTests

- (void)testEmpty {
    
    XCTAssertEqualObjects([KolaFormatWriter stringWithDictionary:@{}], @"");
}

- (void)testBase {
    
    {
        NSDictionary *d = @{};
        XCTAssertEqualObjects([self runDict:d], d);
    }
    
    {
        NSDictionary *d = @{ @"a" : @1 };
        XCTAssertEqualObjects([self runDict:d], d);
    }
    
    {
        NSDictionary *d = @{ @"a" : @[@1, @NO, @{ @"bar" : @"abc", @"foo" : @[] }, @3.14, ] };
        XCTAssertEqualObjects([self runDict:d], d);
    }
}

- (void) testFileSample {
    
    NSString *s = [self stringWithFilePath:@"test.kola"];
    NSDictionary *d = [KolaFormatReader dictionaryWithString:s];
    XCTAssertEqualObjects([self runDict:d], d);
}

- (NSDictionary *) runDict:(NSDictionary *)d
{
    NSString *s = [KolaFormatWriter stringWithDictionary:d];
    return [KolaFormatReader dictionaryWithString:s];
}

- (NSString *) stringWithFilePath:(NSString *)path
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *resPath = bundle.resourcePath;
    resPath = [resPath stringByAppendingPathComponent:path];
    return [NSString stringWithContentsOfFile:resPath encoding:NSUTF8StringEncoding error:nil];
}

@end
