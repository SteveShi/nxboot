#import <NXBootKit/NXVisibility.h>

NXBOOTKIT_PUBLIC extern BOOL NXBootKitDebugEnabled;
NXBOOTKIT_PUBLIC void NXBootKitSetDebugEnabled(BOOL enabled);

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#define NXLog(FORMAT, ...) do { \
    if (NXBootKitDebugEnabled) { \
        NSString *msg = [NSString stringWithFormat:FORMAT, ##__VA_ARGS__]; \
        NSLog(@"%@", msg); \
        dispatch_async(dispatch_get_main_queue(), ^{ \
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NXLogNotification" object:nil userInfo:@{@"message": msg}]; \
        }); \
    } \
} while (0)
#else
#define NXLog(...) do { } while (0)
#endif
