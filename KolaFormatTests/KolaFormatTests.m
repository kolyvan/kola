//
//  KolaFormatTests.m
//  KolaFormatTests
//
//  Created by Kolyvan on 01.12.15.
//  Copyright © 2015 Konstantin Bukreev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KolaFormatReader.h"

@interface KolaFormatTests : XCTestCase

@end

@implementation KolaFormatTests

- (void)testEmpty {
    
    XCTAssertNil([KolaFormatReader dictionaryWithString:@""]);
}

- (void)testBase {

    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a 1"],     @{ @"a" : @1 });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a 'b'"],   @{ @"a" : @"b" });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a []"],    @{ @"a" : @[] });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a {}"],    @{ @"a" : @{} });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a [1]"],   @{ @"a" : @[@1] });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a {b 1}"], @{ @"a" : @{ @"b" : @1 } });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a _"],     @{ @"a" : [NSNull null] });
    
    NSDictionary *d = @{ @"foo" : @"bar", @"PI" : @3.14, @"true" : @NO };
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"foo 'bar' PI 3.14 true false "], d);
}

- (void)testNested {
    
    {
        NSDictionary *d = @{ @"a" : @[@[@[]]] };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a [[[]]]"], d);
    }
    
    {
        NSDictionary *d = @{ @"a" : @[@[@[@1]]] };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a [[[1]]]"], d);
    }
    
    {
        NSDictionary *d =  @{ @"a" : @{ @"b" : @{ @"c" : @{} } } } ;
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a {b{c{}}}"], d);
    }
    
    {
        NSDictionary *d =  @{ @"a" : @{ @"b" : @{ @"c" : @{ @"d" : @1 } } } } ;
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a {b{c{d 1}}}"], d);
    }
}

- (void) testStrings {
    
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"val 'bar'"],  @{ @"val" : @"bar" });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"val 'captain obvious'"],  @{ @"val" : @"captain obvious" });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"val \"kolyvan\""],  @{ @"val" : @"kolyvan" });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"val \"'red'\""],  @{ @"val" : @"'red'" });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"val '\"red\"'"],  @{ @"val" : @"\"red\"" });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"val '\tline 1\n\tline 2\n\tlast line\n'"],  @{ @"val" : @"\tline 1\n\tline 2\n\tlast line\n" });
}

- (void) testNumbers {
    
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"zero 0"],   @{ @"zero" : @0 });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"int 42"],   @{ @"int" : @42 });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"pi 3.14"],  @{ @"pi" : @3.14 });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"neg -7"],   @{ @"neg" : @(-7) });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"f 0.47e12"],@{ @"f" : @0.47e12 });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"42 42"],    @{ @"42" : @42 });
}

- (void) testBooleans {
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"t true"], @{ @"t" : @YES });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"f false"], @{ @"f" : @NO });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"true true"], @{ @"true" : @YES });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"false false"], @{ @"false" : @NO });
}

- (void) testArray {
    
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a []"],    @{ @"a" : @[] });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a [ ]"],   @{ @"a" : @[] });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a [\n]"],  @{ @"a" : @[] });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a [ 1 ]"], @{ @"a" : @[ @1 ] });
    
    {
        NSDictionary *d = @{ @"a" : @[ @1, @2 ] };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a[1 2]"], d);
    }
    
    {
        NSDictionary *d = @{ @"a" : @[ @1, @2, @3, @4 ] };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a[ 1,2\n3 4,]"], d);
    }
    
    {
        NSDictionary *d = @{ @"a" : @[ @1, @"Abc Xyz", @YES ] };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a [1 'Abc Xyz' true]"], d);
    }
    
    {
        NSDictionary *d = @{ @"a" : @[ @1, @[ @2, @3, @[ @4, @5 ] ] ] };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a[1,[2,3,[4,5]]]"], d);
    }
    
    {
        NSDictionary *d = @{ @"a" : @[ @1, @[ @2, @3, @[ @4, @5 ] ] ] };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a [ 1 [ 2 3 [ 4 5 ] ] ]"], d);
    }
}

- (void)testDict {
    
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a {}"], @{ @"a" : @{} });
    XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a { \n }"], @{ @"a" : @{} });
    
    {
        NSDictionary *d = @{ @"a" : @{ @"a" : @1 } };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a{a=1}"], d );
    }
    
    {
        NSDictionary *d = @{ @"a" : @{ @"a" : @1 } };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"a { a 1 }"], d );
    }
    
    {
        NSDictionary *d = @{ @"x" : @{ @"a" : @1, @"b" : @2 , @"c" : @3} };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"x={a=1,b=2,c=3}"], d);
    }
    
    {
        NSDictionary *d = @{ @"x" : @{ @"a" : @1, @"b" : @2 , @"c" : @3} };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"x { a 1 b 2 c 3 }"], d);
    }
    
    {
        NSDictionary *d = @{ @"x" : @{ @"a" : @1, @"b" : @2 , @"c" : @3} };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"x\n{\na 1\nb 2\nc 3\n}"], d);
    }
    
    {
        NSDictionary *d = @{ @"foo" : @{ @"bar" : @{ @"num" : @42 } } };
        XCTAssertEqualObjects([KolaFormatReader dictionaryWithString:@"foo { bar { num 42 } }"], d);
    }
}

- (void) testPlaceholder {
    
    NSDictionary *d = @{ @"foo" : [NSNull null], @"baz" : @{ @"a" : [NSNull null] } };
    NSDictionary *t = [KolaFormatReader dictionaryWithString:@"foo _ baz { a _ }"];
    XCTAssertEqualObjects(t, d);
}

- (void) testReference {
    
    {
        NSDictionary *d = @{ @"foo" : @[ @1, @2 ], @"bar" : @{ @"nums" : @[ @1, @2 ] } };
        NSDictionary *t = [KolaFormatReader dictionaryWithString:@"foo [ 1 2 ] bar { nums foo }"];
        XCTAssertEqualObjects(t, d);
    }
    {
        NSDictionary *d = @{ @"foo" : @{}, @"bar" : @{}, @"baz" : @{} };
        NSDictionary *t = [KolaFormatReader dictionaryWithString:@"foo {} bar foo baz bar"];
        XCTAssertEqualObjects(t, d);
    }
}

- (void) testEnv
{
    NSDictionary *env = @{ @"name" : @"kolyvan", @"value" : @10 };
    NSDictionary *d = @{ @"author" : @"kolyvan", @"number" : @10 };
    NSDictionary *t = [KolaFormatReader dictionaryWithString:@"author name, number value" env:env funcs:nil error:nil];
    XCTAssertEqualObjects(t, d);
}

- (void) testFuncs
{
    NSDictionary *funcs = @{
                           @"timestamp" : ^(id val) {
                               if ([val isKindOfClass:[NSNumber class]]) {
                                   return (id)[NSDate dateWithTimeIntervalSinceReferenceDate:[val floatValue]];
                               }
                               return (id)nil;
                           },
                           };
    
    NSDictionary *d = @{ @"t" : [NSDate dateWithTimeIntervalSinceReferenceDate:12345]  };
    NSDictionary *t = [KolaFormatReader dictionaryWithString:@"t:timestamp 12345" env:nil funcs:funcs error:nil];
    XCTAssertEqualObjects(t, d);
}

- (void) testComments {
    
    {
        NSDictionary *d = @{ @"a" : @1, @"c" : @3  };
        NSDictionary *t = [KolaFormatReader dictionaryWithString:@"#test\na 1 #b 2\nc 3"];
        XCTAssertEqualObjects(t, d);
    }
    
    {
        NSDictionary *d = @{ @"a" : @1, @"c" : @3  };
        NSDictionary *t = [KolaFormatReader dictionaryWithString:@"###\n#z 0\na 1 #b 2\n###\nc 3 #\n##"];
        XCTAssertEqualObjects(t, d);
    }
}

- (void) testErrors {
    
    NSError *error;
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect value"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"{" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"unexpected '{'"]);

    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"[" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"unexpected '['"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"}" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"unexpected '}'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"]" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"unexpected ']'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo {" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect '}'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo [" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect ']'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo }" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect value"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo ]" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect value"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo {]" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    // TODO: must expect '}'
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"unexpected ']'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo [}" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect ']'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo _ {" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"unexpected '{'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo _ [" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"unexpected '['"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo 'fail" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect '''"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"foo 'fail\" abc _" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect '''"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"a [[]" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect ']'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"a {b {}" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect '}'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"a [[b {]]" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    // TODO: must expect '}'
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"unexpected ']'"]);
    
    error = nil;
    XCTAssertNil([KolaFormatReader dictionaryWithString:@"a {b [}" error:&error]);
    XCTAssertEqual(error.code, KolaFormatReaderErrorSyntax);
    XCTAssertTrue([error.localizedFailureReason hasPrefix:@"expect ']'"]);
}

- (void) testUnescape {
    
    {
        NSString *s = @"";
        NSString *t = @"";
        XCTAssertEqualObjects([KolaFormatReader unescapeString:s], t);
    }
    
    {
        NSString *s = @"abc";
        NSString *t = @"abc";
        XCTAssertEqualObjects([KolaFormatReader unescapeString:s], t);
    }
    
    {
       NSString *s = @"\\a\\\\bc";
       NSString *t = @"\a\\bc";
       XCTAssertEqualObjects([KolaFormatReader unescapeString:s], t);
    }
    
    {
        NSString *s = @"\\\\a\\\\b\\\\";
        NSString *t = @"\\a\\b\\";
        XCTAssertEqualObjects([KolaFormatReader unescapeString:s], t);
    }
    
    {
        NSString *s = @"\\\\";
        NSString *t = @"\\";
        XCTAssertEqualObjects([KolaFormatReader unescapeString:s], t);
    }
    
    {
        NSString *s = @"\\n";
        NSString *t = @"\n";
        XCTAssertEqualObjects([KolaFormatReader unescapeString:s], t);
    }
    
    {
        NSString *s = @"\\u2601";
        NSString *t = @"\u2601";
        XCTAssertEqualObjects([KolaFormatReader unescapeString:s], t);
    }
    
    {
        NSString *s = @"\\\\\\n\\t\\b\\x64\\u2601";
        NSString *t = @"\\\n\t\b\x64\u2601";
        XCTAssertEqualObjects([KolaFormatReader unescapeString:s], t);
    }
    
}

@end
