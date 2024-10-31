#import "VideoCache.h"
#import <KTVHTTPCache/KTVHTTPCache.h>
#import <KTVHTTPCache/KTVHCDataLoader.h>

@interface VideoCache ()
@property (nonatomic, strong) NSMutableDictionary *downloaders; // 声明downloaders属性
@end

@implementation VideoCache

RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloaders = [NSMutableDictionary dictionary]; // 初始化downloaders
    }
    return self;
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(convert:(NSString *)url)
{
    if (!KTVHTTPCache.proxyIsRunning) {
      NSError *error;
      [KTVHTTPCache proxyStart:&error];
      if (error) {
        return url;
      }
    }
    NSURL* videoUrl = [NSURL URLWithString:url];
    @try {
        NSURL *completedCacheFileURL = [KTVHTTPCache cacheCompleteFileURLWithURL:videoUrl];
        if (completedCacheFileURL != nil) {
            return completedCacheFileURL.absoluteString;
        }
    }
    @catch (NSException *exception) {
    }
    
    return [KTVHTTPCache proxyURLWithOriginalURL:videoUrl].absoluteString;
}

RCT_EXPORT_METHOD(convertAsync:(NSString *)url
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  if (!KTVHTTPCache.proxyIsRunning) {
    NSError *error;
    [KTVHTTPCache proxyStart:&error];
    if (error) {
      reject(@"init.error", @"failed to start proxy server", error);
      return;
    }
  }
  NSURL* videoUrl = [NSURL URLWithString:url];
  @try {
      NSURL *completedCacheFileURL = [KTVHTTPCache cacheCompleteFileURLWithURL:videoUrl];
      if (completedCacheFileURL != nil) {
          resolve(completedCacheFileURL.absoluteString);
          return;
      }
  }
  @catch (NSException *exception) {
  }
  resolve([KTVHTTPCache proxyURLWithOriginalURL:videoUrl].absoluteString);
}

RCT_EXPORT_METHOD(preload:(NSString *)url
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSURL *videoUrl = [NSURL URLWithString:url];
    
    NSDictionary *headers = @{
        @"Range": @"bytes=0-5000000",  // 预加载前 100 KB 的数据
    };
    
    KTVHCDataRequest *request = [[KTVHCDataRequest alloc] initWithURL:videoUrl headers:headers];
    KTVHCDataLoader *loader = [KTVHTTPCache cacheLoaderWithRequest:request];
    
    loader.delegate = self; // 设置代理以获取预加载状态
    [loader prepare];
    
    // 保持对loader的引用
    [self.downloaders setValue:loader forKey:url]; // 使用url作为key
}

- (void)ktv_dataLoader:(KTVHCDataLoader *)loader
      didUpdateProgress:(float)progress
{
    NSLog(@"Preload progress: %.2f%%", progress * 100);
}

@end
