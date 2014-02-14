//
//  ADBViewController.m
//  ADBDownloadManagerDemo
//
//  Created by Alberto De Bortoli on 11/02/2014.
//  Copyright (c) 2014 Alberto De Bortoli. All rights reserved.
//

#import "ADBViewController.h"
#import "ADBDownloadManager.h"

static NSString *const kBaseRemoteURLDemo = @"https://s3.amazonaws.com/albertodebortoli.github.com/images/adbdownloadmanager/";

@interface ADBViewController () <ADBDownloadManagerDataSource, ADBDownloadManagerDelegate>

@property (nonatomic, strong) ADBDownloadManager *downloadManagerWithoutBaseURL;
@property (nonatomic, strong) ADBDownloadManager *downloadManagerWithBaseURL;
@property (nonatomic, strong) NSArray *fileNamesWithoutBaseURL;
@property (nonatomic, strong) NSArray *fileNamesWithBaseURL;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *downloadManagerWithoutBaseURLIndicatorView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *downloadManagerWithBaseURLIndicatorView;
@property (nonatomic, weak) IBOutlet UIProgressView *downloadManagerWithoutBaseURLProgressView;
@property (nonatomic, weak) IBOutlet UIProgressView *downloadManagerWithBaseURLProgressView;
@property (nonatomic, weak) IBOutlet UITextView *logTextView;

- (IBAction)downloadFiles:(id)sender;
- (IBAction)stopDownloads:(id)sender;
- (IBAction)deleteDownloadedFiles:(id)sender;
- (IBAction)clearConsole:(id)sender;

@end

@implementation ADBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

    self.fileNamesWithoutBaseURL = @[@"bb01.jpg",
                                     @"bb02.jpg",
                                     @"bb03.jpg",
                                     @"bb04.jpg",
                                     @"bb05.jpg"
                                     ];
    self.fileNamesWithBaseURL = @[@"https://s3.amazonaws.com/albertodebortoli.github.com/images/adbdownloadmanager/bb01.jpg",
                                  @"https://s3.amazonaws.com/albertodebortoli.github.com/images/adbdownloadmanager/bb02.jpg",
                                  @"https://s3.amazonaws.com/albertodebortoli.github.com/images/adbdownloadmanager/bb03.jpg",
                                  @"https://s3.amazonaws.com/albertodebortoli.github.com/images/adbdownloadmanager/bb04.jpg",
                                  @"https://s3.amazonaws.com/albertodebortoli.github.com/images/adbdownloadmanager/bb05.jpg"
                                  ];
    
    self.downloadManagerWithoutBaseURLProgressView.progress = 0.0f;
    self.downloadManagerWithBaseURLProgressView.progress = 0.0f;

    self.downloadManagerWithoutBaseURL = [[ADBDownloadManager alloc] initWithLocalPathFolder:documentsDirectory];
    self.downloadManagerWithBaseURL = [[ADBDownloadManager alloc] initWithBaseRemoteURL:kBaseRemoteURLDemo localPathFolder:documentsDirectory];
//    self.downloadManagerWithoutBaseURL.createFoldersHierarchy = NO;

    self.downloadManagerWithoutBaseURL.dataSource = self;
    self.downloadManagerWithoutBaseURL.delegate = self;
    
    self.downloadManagerWithBaseURL.dataSource = self;
    self.downloadManagerWithBaseURL.delegate = self;
}

#pragma mark - ADBDownloadManagerDataSource

- (NSUInteger)numberOfFilesToDownloadForDownloadManager:(ADBDownloadManager *)manager
{
    if (manager == self.downloadManagerWithBaseURL) {
        return [self.fileNamesWithoutBaseURL count];
    }
    return [self.fileNamesWithBaseURL count];
}

- (NSString *)downloadManager:(ADBDownloadManager *)manager pathForFileToDownloadAtIndex:(NSUInteger)index
{
    if (manager == self.downloadManagerWithBaseURL) {
        return [self.fileNamesWithoutBaseURL objectAtIndex:index];
    }
    return [self.fileNamesWithBaseURL objectAtIndex:index];
}

#pragma mark - ADBDownloadManagerDelegate

- (void)downloadManager:(ADBDownloadManager *)manager
 didDownloadFileAtIndex:(NSUInteger)index
          fromRemoteURL:(NSString *)remoteURL
            toLocalPath:(NSString *)localPath
                  bytes:(NSUInteger)bytes
{
    NSLog(@"downloadManager:didDownloadFileAtIndex:fromRemoteURL:toLocalPath:bytes:");
    NSLog(@"\tindex: %lu", (unsigned long)index);
    NSLog(@"\tremoteURL: %@", remoteURL);
    NSLog(@"\tlocalPath: %@", localPath);
    NSLog(@"\tbytes: %lu", (unsigned long)bytes);
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\ndownloadManager:didDownloadFileAtIndex:fromRemoteURL:toLocalPath:bytes:"];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\tindex: %lu", (unsigned long)index]];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\tremoteURL: %@", remoteURL]];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\tlocalPath: %@", localPath]];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\tbytes: %lu", (unsigned long)bytes]];
    [self scrollToBottom];
    
    if (manager == self.downloadManagerWithBaseURL) {
        self.downloadManagerWithBaseURLProgressView.progress = (CGFloat)(index + 1) / (CGFloat)[self.fileNamesWithoutBaseURL count];
    } else {
        self.downloadManagerWithoutBaseURLProgressView.progress = (CGFloat)(index + 1) / (CGFloat)[self.fileNamesWithBaseURL count];
    }
}

- (void)downloadManager:(ADBDownloadManager *)manager
     didFailFileAtIndex:(NSUInteger)index
          fromRemoteURL:(NSString *)remoteURL
            toLocalPath:(NSString *)localPath
                  error:(NSError *)error
{
    NSLog(@"downloadManager:didFailFileAtIndex:fromRemoteURL:toLocalPath:error:");
    NSLog(@"\tindex: %lu", (unsigned long)index);
    NSLog(@"\tremoteURL: %@", remoteURL);
    NSLog(@"\tlocalPath: %@", localPath);
    NSLog(@"\terror: %@", error);
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\ndownloadManager:didFailFileAtIndex:fromRemoteURL:toLocalPath:error:"];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\tindex: %lu", (unsigned long)index]];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\tremoteURL: %@", remoteURL]];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\tlocalPath: %@", localPath]];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\terror: %@", error]];
    [self scrollToBottom];
}

- (void)downloadManagerDidCompleteAllDownloads:(ADBDownloadManager *)manager
                                    failedURLs:(NSArray *)failedURLs
                                    totalBytes:(NSUInteger)totalBytes
{
    NSLog(@"downloadManagerDidCompleteAllDownloads:failedURLs:totalBytes:");
    NSLog(@"\tfailedURLs: %@", failedURLs);
    NSLog(@"\ttotalBytes: %lu", (unsigned long)totalBytes);
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\ndownloadManagerDidCompleteAllDownloads:failedURLs:totalBytes:"];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\tfailedURLs: %@", failedURLs]];
    self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\n\ttotalBytes: %lu", (unsigned long)totalBytes]];
    [self scrollToBottom];
}

- (void)downloadManagerWillStart:(ADBDownloadManager *)manager
{
    NSLog(@"downloadManagerWillStart:");
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\ndownloadManagerWillStart:"];
    [self scrollToBottom];

    if (manager == self.downloadManagerWithBaseURL) {
        [self.downloadManagerWithBaseURLIndicatorView startAnimating];
    } else {
        [self.downloadManagerWithoutBaseURLIndicatorView startAnimating];
    }
}

- (void)downloadManagerDidStop:(ADBDownloadManager *)manager
{
    NSLog(@"downloadManagerDidStop:");
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\ndownloadManagerDidStop:"];
    [self scrollToBottom];
    
    if (manager == self.downloadManagerWithBaseURL) {
        [self.downloadManagerWithBaseURLIndicatorView stopAnimating];
    } else {
        [self.downloadManagerWithoutBaseURLIndicatorView stopAnimating];
    }
}

#pragma mark - Actions

- (IBAction)downloadFiles:(id)sender
{
    [self.downloadManagerWithoutBaseURL start];
    [self.downloadManagerWithBaseURL start];
}

- (IBAction)stopDownloads:(id)sender
{
    [self.downloadManagerWithoutBaseURL stop];
    [self.downloadManagerWithBaseURL stop];
}

- (IBAction)deleteDownloadedFiles:(id)sender
{
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSError * error;
    NSArray * directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:&error];

    NSMutableArray *filePaths = [NSMutableArray array];
    for (NSString *fileName in directoryContent) {
        [filePaths addObject:[documentsDirectory stringByAppendingPathComponent:fileName]];
    }

    for (NSString *filePath in filePaths) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
            NSLog(@"Error deleting file: %@", [error localizedDescription]);
            self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\nError deleting file: %@", [error localizedDescription]]];
            [self scrollToBottom];
        } else {
            NSLog(@"File %@ deleted.", filePath);
            self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\nFile %@ deleted.", filePath]];
            [self scrollToBottom];
        }
    }
}

- (IBAction)clearConsole:(id)sender
{
    self.logTextView.text = @"";
    [self scrollToBottom];
}

#pragma mark - Private

- (void)scrollToBottom
{
    [self.logTextView scrollRangeToVisible:NSMakeRange([self.logTextView.text length], 0)];
    [self.logTextView setScrollEnabled:NO];
    [self.logTextView setScrollEnabled:YES];
}

@end
