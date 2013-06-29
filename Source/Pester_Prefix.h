//
// Prefix header for all source files of the 'Pester' target in the 'Pester' project
//

#ifdef __OBJC__
    #import <Cocoa/Cocoa.h>
    #if !__has_feature(objc_instancetype)
	// Compile with "LLVM compiler 1.7" in Xcode 3.2.6
	#define instancetype id
    #endif
#endif
