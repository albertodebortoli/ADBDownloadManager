//
//  ADBDownloadManager.m
//  v1.2.0
//
//  Created by Alberto De Bortoli on 27/08/2013.
//
//

#import "ADBDownloadManager.h"

@interface ADBDownloadManager ()

@property (atomic, strong) NSString *baseRemoteURL;
@property (atomic, strong) NSString *localPathFolder;
@property (atomic, strong) NSMutableArray *failedURLs;
@property (atomic, assign) NSUInteger numberOfFilesToDownload;
@property (atomic, assign) NSUInteger bytesDownloadedAndSaved;
@property (atomic, assign) BOOL stopAfterCurrentRequest;
@property (atomic, assign) BOOL isRunning;

- (void)_stop;
- (void)_executeItemAtIndex:(NSUInteger)index;

@end

@implementation ADBDownloadManager
{
    dispatch_queue_t _callbackQueue;
}

- (instancetype)initWithLocalPathFolder:(NSString *)localPathFolder
{
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
        _localPathFolder = localPathFolder;
        _baseRemoteURL = @"";
        _callbackQueue = dispatch_get_main_queue();
    }
    
    return self;
}

- (instancetype)initWithBaseRemoteURL:(NSString *)baseRemoteURL localPathFolder:(NSString *)localPathFolder
{
    NSAssert(baseRemoteURL != nil, @"baseRemoteURL must not be nil");
    
    self = [self initWithLocalPathFolder:localPathFolder];
    if (self) {
        _baseRemoteURL = baseRemoteURL;
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)start
{
    if (self.isRunning) {
        return;
    }
    
    self.stopAfterCurrentRequest = NO;
    self.isRunning = YES;

    if ([self.delegate respondsToSelector:@selector(downloadManagerWillStart:)]) {
        dispatch_async(_callbackQueue, ^{
            [self.delegate downloadManagerWillStart:self];
        });
    }
    
    self.numberOfFilesToDownload = [self.dataSource numberOfFilesToDownloadForDownloadManager:self];
    
    if (self.numberOfFilesToDownload > 0) {
        [self _executeItemAtIndex:0];
    }
}

- (void)stop
{
    self.stopAfterCurrentRequest = YES;
}

- (NSUInteger)numberOfDownloadsInSession
{
    return self.numberOfFilesToDownload;
}

#pragma mark - Private Methods

- (void)_stop
{
    [self.failedURLs removeAllObjects];
    self.bytesDownloadedAndSaved = 0;
    self.isRunning = NO;
    if ([self.delegate respondsToSelector:@selector(downloadManagerDidStop:)]) {
        dispatch_async(_callbackQueue, ^{
            [self.delegate downloadManagerDidStop:self];
        });
    }
}

- (void)_executeItemAtIndex:(NSUInteger)index
{
    if (self.stopAfterCurrentRequest) {
        [self _stop];
        return;
    }
    
    __block NSString *pathForFileToDownload = nil;
    pathForFileToDownload = [self.dataSource downloadManager:self pathForFileToDownloadAtIndex:index];
    
    if ([self.baseRemoteURL length] != 0 && ([pathForFileToDownload hasPrefix:@"http"] || [pathForFileToDownload hasPrefix:@"ftp"])) {
        pathForFileToDownload = [pathForFileToDownload stringByReplacingOccurrencesOfString:[pathForFileToDownload pathComponents][0] withString:@""];
    }
    
    NSString *localPath = [self.localPathFolder stringByAppendingPathComponent:pathForFileToDownload];
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath] && (_forceDownload == NO)) {
        // process next
        if (index + 1 < self.numberOfFilesToDownload) {
            [self _executeItemAtIndex:index + 1];
        }
        else {
            if ([self.delegate respondsToSelector:@selector(downloadManagerDidCompleteAllDownloads:failedURLs:totalBytes:)]) {
                dispatch_async(_callbackQueue, ^{
                    [self.delegate downloadManagerDidCompleteAllDownloads:self failedURLs:self.failedURLs totalBytes:self.bytesDownloadedAndSaved];
                });
            }
            [self _stop];
        }
        return;
    }
    
    NSString *urlForFileToDownload = [self.baseRemoteURL stringByAppendingPathComponent:pathForFileToDownload];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlForFileToDownload]];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               // download failed
                               if (connectionError) {
                                   [self.failedURLs addObject:urlForFileToDownload];
                                   
                                   if ([self.delegate respondsToSelector:@selector(downloadManager:didFailFileAtIndex:fromRemoteURL:toLocalPath:error:)]) {
                                       dispatch_async(_callbackQueue, ^{
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
                                           dispatch_async(_callbackQueue, ^{
                                               [self.delegate downloadManager:self
                                                           didFailFileAtIndex:index
                                                                fromRemoteURL:[request.URL absoluteString]
                                                                  toLocalPath:localPath
                                                                        error:error];
                                           });
                                       }
                                   }
                                   else {
                                       self.bytesDownloadedAndSaved += data.length;
                                       if ([self.delegate respondsToSelector:@selector(downloadManager:didDownloadFileAtIndex:fromRemoteURL:toLocalPath:bytes:)]) {
                                           dispatch_async(_callbackQueue, ^{
                                               [self.delegate downloadManager:self
                                                       didDownloadFileAtIndex:index
                                                                fromRemoteURL:[request.URL absoluteString]
                                                                  toLocalPath:localPath
                                                                        bytes:data.length];
                                           });
                                       }
                                   }
                               
                                   // process next
                                   if (index + 1 < self.numberOfFilesToDownload) {
                                       [self _executeItemAtIndex:index + 1];
                                   }
                                   else {
                                       if ([self.delegate respondsToSelector:@selector(downloadManagerDidCompleteAllDownloads:failedURLs:totalBytes:)]) {
                                           dispatch_async(_callbackQueue, ^{
                                               [self.delegate downloadManagerDidCompleteAllDownloads:self
                                                                                          failedURLs:self.failedURLs
                                                                                          totalBytes:self.bytesDownloadedAndSaved];
                                           });
                                       }
                                       [self _stop];
                                   }
                               }
                           }];
}

@end
