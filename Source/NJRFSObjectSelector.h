/* NJRFSObjectSelector */

#import <Cocoa/Cocoa.h>
#import "BDAlias.h"

@interface NJRFSObjectSelector : NSButton
{
    BDAlias *selectedAlias;
    NSArray *fileTypes;
    BOOL canChooseDirectories;
    BOOL canChooseFiles;
    BOOL dragAccepted;
    BOOL isEnabled;
}
- (IBAction)select:(id)sender;
- (void)setAlias:(BDAlias *)alias;
- (BDAlias *)alias;
- (BOOL)acceptsPath:(NSString *)path;
- (void)setPath:(NSString *)path; // does not validate
- (BOOL)canChooseDirectories;
- (BOOL)canChooseFiles;
- (void)setCanChooseDirectories:(BOOL)flag;
- (void)setCanChooseFiles:(BOOL)flag;
- (NSArray *)fileTypes;
- (void)setFileTypes:(NSArray *)types;

@end
