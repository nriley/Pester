//
//  PSScriptAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSScriptAlert.h"
#import "BDAlias.h"
#import "NSDictionary-NJRExtensions.h"

// property list keys
static NSString * const PLAlertAlias = @"alias"; // NSData

@implementation PSScriptAlert

+ (PSScriptAlert *)alertWithScriptFileAlias:(BDAlias *)anAlias;
{
    return [[[self alloc] initWithScriptFileAlias: anAlias] autorelease];
}

- (id)initWithScriptFileAlias:(BDAlias *)anAlias;
{
    if ( (self = [super init]) != nil) {
        alias = [anAlias retain];
    }
    return self;
}

- (BDAlias *)scriptFileAlias;
{
    return alias;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    NSString *scriptPath = [alias fullPath];

    if (scriptPath == nil) {
        NSRunAlertPanel(NSLocalizedString(@"Can't find script", "Title of alert sheet when alias to script didn't resolve"), NSLocalizedString(@"Pester couldn't find the script for the alarm '%@'.", "Message displayed in alert sheet when alias to script didn't resolve"),
                        nil, nil, nil, [alarm message]);
    } else {
        NSDictionary *errorInfo;
        NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL: [NSURL fileURLWithPath: scriptPath] error: &errorInfo];
        if (script == nil) {
            NSString *errorMessage = [errorInfo objectForKey: NSAppleScriptErrorMessage];
            NSNumber *errorNumber = [errorInfo objectForKey: NSAppleScriptErrorNumber];
            NSString *appName = [errorInfo objectForKey: NSAppleScriptErrorAppName];
            if (errorMessage == nil) errorMessage = [errorInfo objectForKey: NSAppleScriptErrorBriefMessage];
            NSRunAlertPanel(@"Script loading error",
                            @"Pester encountered an error while attempting to load “%@”%@ %@",
                            nil, nil, nil,
                            [[NSFileManager defaultManager] displayNameAtPath: scriptPath],
                            errorMessage == nil ? @"" : [NSString stringWithFormat: @":\n\n%@%@", appName == nil ? @"" : @"“%@” reported an error: ", errorMessage],
                            errorNumber == nil ? @"" : [NSString stringWithFormat: @"(%@)", errorNumber]);
        } else {
            NSAppleEventDescriptor *scriptResult = [script executeAndReturnError: &errorInfo];
            if (scriptResult == nil) {
                NSString *errorMessage = [errorInfo objectForKey: NSAppleScriptErrorMessage];
                NSNumber *errorNumber = [errorInfo objectForKey: NSAppleScriptErrorNumber];
                NSString *appName = [errorInfo objectForKey: NSAppleScriptErrorAppName];
                if (errorMessage == nil) errorMessage = [errorInfo objectForKey: NSAppleScriptErrorBriefMessage];
                NSRunAlertPanel(@"Script execution error",
                                @"Pester encountered an error while attempting to execute the script “%@”%@ %@",
                                nil, nil, nil,
                                [[NSFileManager defaultManager] displayNameAtPath: scriptPath],
                                errorMessage == nil ? @"" : [NSString stringWithFormat: @":\n\n%@%@", appName == nil ? @"" : @"“%@” reported an error: ", errorMessage],
                                errorNumber == nil ? @"" : [NSString stringWithFormat: @"(%@)", errorNumber]);
            }
        }
    }
    [self completedForAlarm: alarm];
}

- (NSAttributedString *)actionDescription;
{
    NSMutableAttributedString *string = [[@"Do script " small] mutableCopy];
    NSString *scriptName = [alias displayNameWithKindString: NULL];
    if (scriptName == nil) scriptName = NSLocalizedString(@"<<can't locate script>>", "Script alert description surrogate for script name when alias doesn't resolve");
    [string appendAttributedString: [scriptName underlined]];
    return [string autorelease];
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *plAlert = [[super propertyListRepresentation] mutableCopy];
    [plAlert setObject: [alias aliasData] forKey: PLAlertAlias];
    return [plAlert autorelease];
}

- (instancetype)initWithPropertyList:(NSDictionary *)dict;
{
    return [self initWithScriptFileAlias: [BDAlias aliasWithData: [dict objectForRequiredKey: PLAlertAlias]]];
}

@end
