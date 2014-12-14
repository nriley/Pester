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
    fprintf(stderr, ">>>> Initialized %s in %.3f seconds.\n", [name UTF8String], (after - before) / (float)CLOCKS_PER_SEC);
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

- (BOOL)setUpForLocaleLanguageCode:(NSString *)localeLanguageCode;
{
    init_date_parser_on_queue(localeLanguageCode);
    if (parse_natural_language_date_on_queue(nil) != nil) {
        XCTFail(@"initializing locale language code '%@'", localeLanguageCode);
        return NO;
    }

    calendar.locale = [NSLocale localeWithLocaleIdentifier:localeLanguageCode];
    return YES;
}

- (void)testWeekdaySupportedLocales;
{
    for (NSString *localeLanguageCode in date_parser_supported_locale_language_codes()) {
        if (![self setUpForLocaleLanguageCode:localeLanguageCode])
            continue;

        NSInteger weekday = 1;
        for (NSString *weekdaySymbol in calendar.weekdaySymbols) {
            NSDate *parsedDate = parse_natural_language_date_on_queue(weekdaySymbol);
            NSInteger parsedWeekday = [calendar component:NSCalendarUnitWeekday fromDate:parsedDate];
            XCTAssertEqual(parsedWeekday, weekday, @"locale '%@' weekday '%@'", localeLanguageCode, weekdaySymbol);
            weekday++;
        }
    }
}

- (void)testDateCompletionSupportedLocales;
{
    NSArray *localizations = [bundle localizations];

    for (NSString *localeLanguageCode in localizations) {
        if ([localeLanguageCode isEqualToString:@"hr"]) // have a .strings file for Croatian, but no Date::Manip support
            continue;

        if (![self setUpForLocaleLanguageCode:localeLanguageCode])
            continue;

        NSDictionary *dateCompletions = [NSDictionary dictionaryWithContentsOfFile:[bundle pathForResource:@"DateCompletions" ofType:@"strings" inDirectory:nil forLocalization:localeLanguageCode]];

        for (NSString *unlocalizedDateCompletion in dateCompletions) {
            NSString *localizedDateCompletion = dateCompletions[unlocalizedDateCompletion];
            NSDateComponents *components = [[NSDateComponents alloc] init];
            NSDate *date = [NSDate date];
            date = [calendar startOfDayForDate:date];

            if ([unlocalizedDateCompletion isEqualToString:@"today"]) {
                // today
            } else if ([unlocalizedDateCompletion isEqualToString:@"tomorrow"]) {
                components.day = 1;
            } else if ([unlocalizedDateCompletion isEqualToString:@"in 2 days"]) {
                components.day = 2;
            } else if ([unlocalizedDateCompletion isEqualToString:@"next week"]) {
                components.weekOfMonth = 1;
            } else if ([unlocalizedDateCompletion isEqualToString:@"in 2 weeks"]) {
                components.weekOfMonth = 2;
            } else if ([unlocalizedDateCompletion isEqualToString:@"next month"]) {
                components.month = 1;
            } else if ([unlocalizedDateCompletion isEqualToString:@"in 2 months"]) {
                components.month = 2;
            } else if ([unlocalizedDateCompletion isEqualToString:@"in 1 year"]) {
                components.year = 1;
            } else if ([unlocalizedDateCompletion isEqualToString:@"next «day»"]) {
                NSInteger weekday = 1;
                for (NSString *weekdaySymbol in calendar.weekdaySymbols) {
                    NSDate *nextWeekdayDate = [calendar dateBySettingUnit:NSCalendarUnitWeekday value:weekday ofDate:date options:NSCalendarMatchStrictly];
                    weekday++;
                    if ([date earlierDate:nextWeekdayDate] == nextWeekdayDate)
                        nextWeekdayDate = [calendar dateByAddingUnit:NSCalendarUnitWeekOfMonth value:1 toDate:nextWeekdayDate options:NSCalendarMatchStrictly];
                    NSString *localizedNextWeekday = [localizedDateCompletion stringByReplacingOccurrencesOfString:@"«day»" withString:weekdaySymbol];
                    NSDate *parsedDate = parse_natural_language_date_on_queue(localizedNextWeekday);
                    XCTAssertNotNil(parsedDate, @"locale '%@' next weekday '%@'", localeLanguageCode, localizedNextWeekday);
                    if (parsedDate == nil)
                        continue;
                    parsedDate = [calendar startOfDayForDate:parsedDate];
                    XCTAssertEqualObjects(parsedDate, nextWeekdayDate, @"locale '%@' next weekday '%@'", localeLanguageCode, localizedNextWeekday);
                }
                continue;
            } else {
                XCTFail(@"unexpected date completion '%@'", unlocalizedDateCompletion);
                continue;
            }

            date = [calendar dateByAddingComponents:components toDate:date options:NSCalendarMatchStrictly];
            [components release];

            NSDate *parsedDate = parse_natural_language_date_on_queue(localizedDateCompletion);
            XCTAssertNotNil(parsedDate, @"locale '%@' date completion '%@'", localeLanguageCode, localizedDateCompletion);
            if (parsedDate == nil)
                continue;
            parsedDate = [calendar startOfDayForDate:parsedDate];
            XCTAssertEqualObjects(parsedDate, date, @"locale '%@' date completion '%@'", localeLanguageCode, localizedDateCompletion);
        }
    }
}

@end
