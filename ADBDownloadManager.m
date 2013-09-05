//
//  ADBDownloadManager.m
//  v1.0.0
//
//  Created by Alberto De Bortoli on 27/08/2013.
//
//

#import "ADBDownloadManager.h"

@interface ADBDownloadManager ()

- (void)_stop;
- (void)_executeItemAtIndex:(NSUInteger)index;

@end

@implementation ADBDownloadManager
{
    NSString *_baseRemoteURL;
    NSString *_localPathFolder;
    NSMutableArray *_failedURLs;
    NSOperationQueue *_queue;
    NSUInteger _numberOfFilesToDownload;
    NSUInteger _bytesDownloadedAndSaved;
    BOOL _stopAfterCurrentRequest;
    BOOL _isRunning;
}

- (instancetype)initWithBaseRemoteURL:(NSString *)baseRemoteURL localPathFolder:(NSString *)localPathFolder queue:(NSOperationQueue *)queue
{
    NSAssert(baseRemoteURL != nil, @"baseRemoteURL must not be nil");
    NSAssert(localPathFolder != nil, @"localPathFolder must not be nil");
    
    self = [super init];
    if (self) {
        _forceDownload = NO;
        _failedURLs = [NSMutableArray array];
        _forceDownload = NO;
        _numberOfFilesToDownload = 0;
        _bytesDownloadedAndSaved = 0;
        _stopAfterCurrentRequest = NO;
        _isRunning = NO;
        _baseRemoteURL = baseRemoteURL;
        _localPathFolder = localPathFolder;
        _queue = queue;
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)start
{
    if (_isRunning) {
        return;
    }
    
    _isRunning = YES;

    if ([self.delegate respondsToSelector:@selector(downloadManagerWillStart:)]) {
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.delegate downloadManagerWillStart:self];
        });
    }
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        _numberOfFilesToDownload = [self.dataSource numberOfFilesToDownloadForDownloadManager:self];
    });
    if (_numberOfFilesToDownload > 0) {
        [self _executeItemAtIndex:0];
    }
}

- (void)stop
{
    _stopAfterCurrentRequest = YES;
}

- (NSUInteger)numberOfDownloadsInSession
{
    return _numberOfFilesToDownload;
}

#pragma mark - Private Methods

- (void)_stop
{
    [_failedURLs removeAllObjects];
    _bytesDownloadedAndSaved = 0;
    _isRunning = NO;
    if ([self.delegate respondsToSelector:@selector(downloadManagerDidStop:)]) {
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.delegate downloadManagerDidStop:self];
        });
    }
}

- (void)_executeItemAtIndex:(NSUInteger)index
{
    if (_stopAfterCurrentRequest) {
        [self _stop];
        return;
    }
    
    __block NSString *pathForFileToDownload = nil;
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        pathForFileToDownload = [self.dataSource downloadManager:self pathForFileToDownloadAtIndex:index];
    });
    
    if ([pathForFileToDownload hasPrefix:@"http"] || [pathForFileToDownload hasPrefix:@"ftp"]) {
        pathForFileToDownload = [pathForFileToDownload stringByReplacingOccurrencesOfString:[pathForFileToDownload pathComponents][0] withString:@""];
    }
    
    NSString *localPath = [_localPathFolder stringByAppendingPathComponent:pathForFileToDownload];
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath] && (_forceDownload == NO)) {
        // process next
        if (index + 1 < _numberOfFilesToDownload) {
            [self _executeItemAtIndex:index + 1];
        }
        else {
            if ([self.delegate respondsToSelector:@selector(downloadManagerDidCompleteAllDownloads:failedURLs:totalBytes:)]) {
                dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [self.delegate downloadManagerDidCompleteAllDownloads:self failedURLs:_failedURLs totalBytes:_bytesDownloadedAndSaved];
                });
            }
            [self _stop];
        }
        return;
    }
    
    NSString *urlForFileToDownload = [_baseRemoteURL stringByAppendingPathComponent:pathForFileToDownload];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlForFileToDownload]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:_queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               // download failed
                               if (connectionError) {
                                   [_failedURLs addObject:urlForFileToDownload];
                                   
                                   if ([self.delegate respondsToSelector:@selector(downloadManager:didFailFileAtIndex:fromRemoteURL:toLocalPath:error:)]) {
                                       dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                           [self.delegate downloadManager:self didFailFileAtIndex:index
                                                            fromRemoteURL:[request.URL absoluteString]
                                                              toLocalPath:localPath
                                                                    error:connectionError];
                                       });
                                   }
                               }
                               // download succeeded
                               else {
                                   NSError *error = nil;
                                   
                                   // save on disk
                                   [[NSFileManager defaultManager] createDirectoryAtPath:[localPath stringByDeletingLastPathComponent]
                                                             withIntermediateDirectories:YES
                                                                              attributes:nil
                                                                                   error:&error];
                                   [data writeToFile:localPath options:NSDataWritingAtomic error:&error];
                                   
                                   if (error) {
                                       if ([self.delegate respondsToSelector:@selector(downloadManager:didFailFileAtIndex:fromRemoteURL:toLocalPath:error:)]) {
                                           dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                               [self.delegate downloadManager:self
                                                           didFailFileAtIndex:index
                                                                fromRemoteURL:[request.URL absoluteString]
                                                                  toLocalPath:localPath
                                                                        error:error];
                                           });
                                       }
                                   }
                                   else {
                                       _bytesDownloadedAndSaved += data.length;
                                       if ([self.delegate respondsToSelector:@selector(downloadManager:didDownloadFileAtIndex:fromRemoteURL:toLocalPath:bytes:)]) {
                                           dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                               [self.delegate downloadManager:self
                                                       didDownloadFileAtIndex:index
                                                                fromRemoteURL:[request.URL absoluteString]
                                                                  toLocalPath:localPath
                                                                        bytes:data.length];
                                           });
                                       }
                                   }
                               
                                   // process next
                                   if (index + 1 < _numberOfFilesToDownload) {
                                       [self _executeItemAtIndex:index + 1];
                                   }
                                   else {
                                       if ([self.delegate respondsToSelector:@selector(downloadManagerDidCompleteAllDownloads:failedURLs:totalBytes:)]) {
                                           dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                               [self.delegate downloadManagerDidCompleteAllDownloads:self
                                                                                          failedURLs:_failedURLs
                                                                                          totalBytes:_bytesDownloadedAndSaved];
                                           });
                                       }
                                       [self _stop];
                                   }
                               }
                           }];
}

@end
