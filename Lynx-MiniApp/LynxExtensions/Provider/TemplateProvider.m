//
//  TemplateProvider.m
//  ttest
//
//  Created by 김수환 on 11/1/25.
//

#import "TemplateProvider.h"

@implementation TemplateProvider

- (void)loadTemplateWithUrl:(NSString*)url onComplete:(LynxTemplateLoadBlock)callback {
  NSString* encodeUrl =
      [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet
                                                                  URLFragmentAllowedCharacterSet]];
  NSURL* nsUrl = [NSURL URLWithString:encodeUrl];
  NSURLSessionDataTask* task = [[NSURLSession sharedSession]
        dataTaskWithURL:nsUrl
      completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response,
                          NSError* _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (error) {
            callback(data, error);
          } else if (!data) {
            NSMutableDictionary* details = [NSMutableDictionary new];
            NSString* errorMsg = [NSString stringWithFormat:@"data from %@ is nil!", url];
            [details setObject:errorMsg forKey:NSLocalizedDescriptionKey];
            NSError* data_error = [NSError errorWithDomain:@"miniapp.lynx" code:200 userInfo:details];
            callback(nil, data_error);
          } else {
            callback(data, nil);
          }
        });
      }];
  [task resume];
}

@end
