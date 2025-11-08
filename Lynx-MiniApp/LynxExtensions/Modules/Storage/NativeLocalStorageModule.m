//
//  NativeLocalStorageModule.m
//  ttest
//
//  Created by 김수환 on 11/1/25.
//

#import "NativeLocalStorageModule.h"

@interface NativeLocalStorageModule()
@property (strong, nonatomic) NSUserDefaults *localStorage;
@end

@implementation NativeLocalStorageModule

static NSString *const NativeLocalStorageKey = @"MyLocalStorage";

- (instancetype)init {
    if (self = [super init]) {
        _localStorage = [[NSUserDefaults alloc] initWithSuiteName:NativeLocalStorageKey];
    }
    return self;
}

+ (NSString *)name {
    return @"NativeLocalStorageModule";
}

+ (NSDictionary<NSString *, NSString *> *)methodLookup {
    return @{
        @"setStorageItem": NSStringFromSelector(@selector(setStorageItem:value:)),
        @"getStorageItem": NSStringFromSelector(@selector(getStorageItem:callback:)),
        @"clearStorage": NSStringFromSelector(@selector(clearStorage))
    };
}

- (void)setStorageItem:(NSString *)key value:(NSString *)value {
    [self.localStorage setObject:value forKey:key];
}

- (void)getStorageItem:(NSString *)key callback:(void(^)(NSString *value)) callback{
    NSString *value = [self.localStorage stringForKey:key];
    callback(value);
}

- (void)clearStorage {
    NSDictionary *keys = [self.localStorage dictionaryRepresentation];
    for (NSString *key in keys) {
        [self.localStorage removeObjectForKey:key];
    }
}

@end
