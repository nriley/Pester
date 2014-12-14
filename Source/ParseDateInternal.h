//
//  ParseDateInternal.h
//  Pester
//
//  Created by Nicholas Riley on 12/14/14.
//
//

// non-asynchronous/GCD-using entry points for testing

// init_date_parser_on_queue would ordinarily call this, but need to override module search path
BOOL init_perl_on_queue(NSString *moduleSearchPath);
void init_date_parser_on_queue(NSString *localeLanguageCode);
NSDate *parse_natural_language_date_on_queue(NSString *input);

// list of Date::Manip-supported language codes for testing
NSArray *date_parser_supported_locale_language_codes(void);