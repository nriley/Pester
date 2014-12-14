//
//  ParseDateTest.m
//  ParseDateTest
//
//  Created by Nicholas Riley on 12/14/14.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "ParseDateInternal.h"

@interface ParseDateTest : XCTestCase
{
    NSBundle *bundle;
    NSCalendar *calendar;
}
@end

@implementation ParseDateTest

- (void)timeInitializationOf:(NSString *)name block:(void (^)(void))block;
{
    // For one-time operations expected to be relatively time-consuming (>0.1s), sometimes I/O bound; ballpark precision/accuracy is adequate.
    // Can't use XCTest measurements because it wants to repeat the block.
    clock_t before = clock();
    block();
    clock_t after = clock();
    XCTAssertNotEqual(before, -1);
    XCTAssertNotEqual(after, -1);
    fprintf(stderr, ">>>> Initialization of %s - %.3f seconds.\n", [name UTF8String], (after - before) / (float)CLOCKS_PER_SEC);
}

- (void)setUp;
{
    [super setUp];

    bundle = [[NSBundle bundleForClass:[self class]] retain];
    calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];

    static BOOL perlInitialized;

    if (!perlInitialized) {
        [self timeInitializationOf:@"Perl" block:^{
            perlInitialized = init_perl_on_queue([[NSBundle bundleForClass:[self class]] resourcePath]);
            XCTAssertTrue(perlInitialized);
        }];

        [self timeInitializationOf:@"Date::Manip" block:^{
            init_date_parser_on_queue(nil);
            XCTAssertNil(parse_natural_language_date_on_queue(nil));
        }];
    }
}

- (void)tearDown;
{
    [bundle release];
    [calendar release];

    [super tearDown];
}

- (void)testReinitializationPerformance;
{
    [self measureBlock:^{
        init_date_parser_on_queue(nil);
    }];
    XCTAssertNil(parse_natural_language_date_on_queue(nil));
}

- (void)testWeekdaySupportedLocales;
{
    for (NSString *localeLanguageCode in date_parser_supported_locale_language_codes()) {
        init_date_parser_on_queue(localeLanguageCode);
        XCTAssertNil(parse_natural_language_date_on_queue(nil), @"failed to initialize locale language code '%@'", localeLanguageCode);

        // weekdays
        calendar.locale = [NSLocale localeWithLocaleIdentifier:localeLanguageCode];

        NSInteger weekday = 1;
        for (NSString *weekdaySymbol in calendar.weekdaySymbols) {
            NSDate *parsedDate = parse_natural_language_date_on_queue(weekdaySymbol);
            NSInteger parsedWeekday = [calendar component:NSCalendarUnitWeekday fromDate:parsedDate];
            XCTAssertEqual(parsedWeekday, weekday, @"locale '%@' weekday '%@'", localeLanguageCode, weekdaySymbol);
            weekday++;
        }
    }
}

@end
