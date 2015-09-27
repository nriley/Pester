/*******************************************************************************
    BDAlias.m
        Copyright (c) 2001-2002 bDistributed.com, Inc.
        Copyright (c) 2002-2009 BDAlias developers
        Some rights reserved: <http://opensource.org/licenses/mit-license.php>

    ***************************************************************************/

#include <assert.h>

#import "BDAlias.h"


static Handle DataToHandle(CFDataRef inData);
static CFDataRef HandleToData(Handle inHandle);

static OSStatus PathToFSRef(CFStringRef inPath, FSRef *outRef);
static CFStringRef FSRefToPathCopy(const FSRef *inRef);


static Handle DataToHandle(CFDataRef inData)
{
    CFIndex	len;
    Handle	handle = NULL;
    
    if (inData == NULL) {
        return NULL;
    }
    
    len = CFDataGetLength(inData);
    
    PtrToHand(CFDataGetBytePtr(inData), (Handle*)&handle, len);
    
    return handle;
}

static CFDataRef HandleToData(Handle inHandle)
{
    CFDataRef	data = NULL;
    CFIndex	len;
    SInt8	handleState;
    
    if (inHandle == NULL) {
        return NULL;
    }
    
    len = GetHandleSize(inHandle);
    
    handleState = HGetState(inHandle);
    
    HLock(inHandle);
    
    data = CFDataCreate(kCFAllocatorDefault, (const UInt8 *) *inHandle, len);
    
    HSetState(inHandle, handleState);
    
    return data;
}

static OSStatus PathToFSRef(CFStringRef inPath, FSRef *outRef)
{
    CFURLRef	tempURL = NULL;
    Boolean	gotRef = false;
    
    tempURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, inPath,
                                            kCFURLPOSIXPathStyle, false);
    
    if (tempURL == NULL) {
        return fnfErr;
    }
    
    gotRef = CFURLGetFSRef(tempURL, outRef);
    
    CFRelease(tempURL);
    
    if (gotRef == false) {
        return fnfErr;
    }
    
    return noErr;
}

static CFStringRef FSRefToPathCopy(const FSRef *inRef)
{
    CFURLRef	tempURL = NULL;
    CFStringRef	result = NULL;
    
    if (inRef != NULL) {
        tempURL = CFURLCreateFromFSRef(kCFAllocatorDefault, inRef);
        
        if (tempURL == NULL) {
            return NULL;
        }
        
        result = CFURLCopyFileSystemPath(tempURL, kCFURLPOSIXPathStyle);
        
        CFRelease(tempURL);
    }
    
    return result;
}


@implementation BDAlias

- (id)initWithAliasHandle:(AliasHandle)alias
{
    if ( (self = [super init]) != nil) {
        _alias = alias;
    }
    
    return self;
}

- (id)initWithData:(NSData *)data
{
    return [self initWithAliasHandle:(AliasHandle)DataToHandle((CFDataRef) data)];
}

- (id)initWithPath:(NSString *)fullPath
{
   return [self initWithPath:fullPath error:nil];
}

- (id)initWithPath:(NSString *)fullPath error:(NSError **)outError
{
    OSStatus	anErr = noErr;
    FSRef		ref;
    
    anErr = PathToFSRef((CFStringRef) fullPath, &ref);
    
    if (anErr != noErr) {
        if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:anErr userInfo:nil];
        return nil;
    }
    
    return [self initWithFSRef:&ref error:outError];
}

- (id)initWithPath:(NSString *)path relativeToPath:(NSString *)relPath
{
    OSStatus	anErr = noErr;
    FSRef		ref, relRef;
    
    anErr = PathToFSRef((CFStringRef) [relPath stringByAppendingPathComponent:path],
                        &ref);
    
    if (anErr != noErr) {
        return nil;
    }
    
    anErr = PathToFSRef((CFStringRef) relPath, &relRef);
    
    if (anErr != noErr) {
        return nil;
    }
    
    return [self initWithFSRef:&ref relativeToFSRef:&relRef];
}

- (id)initWithFSRef:(FSRef *)ref
{
    return [self initWithFSRef:ref relativeToFSRef:NULL];
}

- (id)initWithFSRef:(FSRef *)ref error:(NSError **)outError
{
    return [self initWithFSRef:ref relativeToFSRef:NULL error:outError];
}

- (id)initWithFSRef:(FSRef *)ref relativeToFSRef:(FSRef *)relRef
{
    return [self initWithFSRef:ref relativeToFSRef:relRef error:nil];
}

- (id)initWithFSRef:(FSRef *)ref relativeToFSRef:(FSRef *)relRef error:(NSError **)outError
{
    OSStatus	anErr = noErr;
    AliasHandle	alias = NULL;
    
    anErr = FSNewAlias(relRef, ref, &alias);
    
    if (anErr != noErr) {
        if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:anErr userInfo:nil];
        return nil;
    }
    
    return [self initWithAliasHandle:alias];
}

- (id)initWithCoder:(NSCoder *)coder
{
    return [self initWithData:[coder decodeDataObject]];
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeDataObject:[self aliasData]];
}

- (void)dealloc
{
    if (_alias != NULL) {
        DisposeHandle((Handle) _alias);
        _alias = NULL;
    }
    
    [super dealloc];
}

- (AliasHandle)alias
{
    return _alias;
}

- (void)setAlias:(AliasHandle)newAlias
{
    if (_alias != NULL) {
        DisposeHandle((Handle) _alias);
    }
    
    _alias = newAlias;
}

- (NSData *)aliasData
{
    NSData *result;
    
    result = (NSData *)HandleToData((Handle) _alias);
    
    return [result autorelease];
}

- (void)setAliasData:(NSData *)newAliasData
{
    [self setAlias:(AliasHandle) DataToHandle((CFDataRef) newAliasData)];
}

- (NSString *)displayNameWithKindString:(NSString **)outKindString;
{
    AliasHandle alias = [self alias];
    FSRef ref;
    Boolean wasChanged;
    CFStringRef name;

    if (alias == NULL) return nil;
    if (FSResolveAlias(NULL, alias, &ref, &wasChanged) != noErr) return nil;

    if (LSCopyDisplayNameForRef(&ref, &name) != noErr) return nil;
    [(NSString *)name autorelease];

    if (outKindString != NULL) {
        if (LSCopyKindStringForRef(&ref, (CFStringRef *)outKindString) != noErr) return nil;
        [*outKindString autorelease];
    }

    return (NSString *)name;
}

- (NSURL *)fileURL
{
    NSString *path = [self fullPath];
    if (path == nil)
        return nil;
    return [NSURL fileURLWithPath: path];
}

- (NSString *)fullPath
{
    return [self fullPathRelativeToPath:nil];
}

- (NSString *)fullPathRelativeToPath:(NSString *)relPath
{
    OSStatus	anErr = noErr;
    FSRef	relPathRef;
    FSRef	tempRef;
    NSString	*result = nil;
    Boolean	wasChanged;
    
    if (_alias != NULL) {
        if (relPath != nil) {
            anErr = PathToFSRef((CFStringRef)relPath, &relPathRef);
            
            if (anErr != noErr) {
                return NULL;
            }
            
            anErr = FSResolveAlias(&relPathRef, _alias, &tempRef, &wasChanged);
        } else {
            anErr = FSResolveAlias(NULL, _alias, &tempRef, &wasChanged);
        }
        
        if (anErr != noErr) {
            return NULL;
        }
        
        result = (NSString *)FSRefToPathCopy(&tempRef);
    }
    
    return [result autorelease];
}

+ (BDAlias *)aliasWithAliasHandle:(AliasHandle)alias
{
    return [[[BDAlias alloc] initWithAliasHandle:alias] autorelease];
}

+ (BDAlias *)aliasWithData:(NSData *)data
{
    return [[[BDAlias alloc] initWithData:data] autorelease];
}

+ (BDAlias *)aliasWithPath:(NSString *)fullPath
{
    return [[[BDAlias alloc] initWithPath:fullPath] autorelease];
}

+ (BDAlias *)aliasWithPath:(NSString *)fullPath error:(NSError **)outError
{
    return [[[BDAlias alloc] initWithPath:fullPath error:outError] autorelease];
}

+ (BDAlias *)aliasWithPath:(NSString *)path relativeToPath:(NSString *)relPath
{
    return [[[BDAlias alloc] initWithPath:path relativeToPath:relPath] autorelease];
}

+ (BDAlias *)aliasWithFSRef:(FSRef *)ref
{
    return [[[BDAlias alloc] initWithFSRef:ref] autorelease];
}

+ (BDAlias *)aliasWithFSRef:(FSRef *)ref relativeToFSRef:(FSRef *)relRef
{
    return [[[BDAlias alloc] initWithFSRef:ref relativeToFSRef:relRef] autorelease];
}

- (BOOL)aliasIsEqual:(AliasHandle)otherAlias;
{
    AliasHandle alias = [self alias];
    FSRef ref, otherRef;
    Boolean wasChanged;

    if (alias == otherAlias) return YES;
    if (alias == NULL || otherAlias == NULL) return NO;
    if (FSResolveAlias(NULL, alias, &ref, &wasChanged) != noErr) return NO;
    if (FSResolveAlias(NULL, otherAlias, &otherRef, &wasChanged) != noErr) return NO;
    return (FSCompareFSRefs(&ref, &otherRef) == noErr);
}

- (BOOL)aliasDataIsEqual:(NSData *)data;
{
    BOOL result;
    AliasHandle otherAlias = (AliasHandle)DataToHandle((CFDataRef)data);
    result = [self aliasIsEqual: otherAlias];
    DisposeHandle((Handle)otherAlias);
    return result;
}

- (BOOL)isEqual:(id)object;
{
    if (![object isKindOfClass: [BDAlias class]]) return NO;
    return [self aliasIsEqual: [object alias]];
}

@end
