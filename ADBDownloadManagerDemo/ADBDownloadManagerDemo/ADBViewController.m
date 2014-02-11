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

@property (nonatomic, strong) ADBDownloadManager *downloadManager;
@property (nonatomic, strong) NSArray *fileNames;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *indicatorView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
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

    self.fileNames = @[@"bb01.jpg", @"bb02.jpg", @"bb03.jpg", @"bb04.jpg", @"bb05.jpg"];
    self.progressView.progress = 0.0f;

    self.downloadManager = [[ADBDownloadManager alloc] initWithBaseRemoteURL:kBaseRemoteURLDemo
                                                             localPathFolder:documentsDirectory];
    self.downloadManager.dataSource = self;
    self.downloadManager.delegate = self;
}

#pragma mark - ADBDownloadManagerDataSource

- (NSUInteger)numberOfFilesToDownloadForDownloadManager:(ADBDownloadManager *)manager
{
    return 5;
}

- (NSString *)downloadManager:(ADBDownloadManager *)manager pathForFileToDownloadAtIndex:(NSUInteger)index
{
    return [self.fileNames objectAtIndex:index];
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
    
    self.progressView.progress = (CGFloat)(index + 1) / (CGFloat)[self.fileNames count];
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
}

- (void)downloadManagerWillStart:(ADBDownloadManager *)manager
{
    NSLog(@"downloadManagerWillStart:");
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\ndownloadManagerWillStart:"];
    [self.indicatorView startAnimating];
}

- (void)downloadManagerDidStop:(ADBDownloadManager *)manager
{
    NSLog(@"downloadManagerDidStop:");
    self.logTextView.text = [self.logTextView.text stringByAppendingString:@"\ndownloadManagerDidStop:"];
    [self.indicatorView stopAnimating];
}

#pragma mark - Actions

- (IBAction)downloadFiles:(id)sender
{
    [self.downloadManager start];
}

- (IBAction)stopDownloads:(id)sender
{
    [self.downloadManager stop];
}

- (IBAction)deleteDownloadedFiles:(id)sender
{
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    for (NSString *file in self.fileNames) {
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
            NSLog(@"Error deleting file: %@", [error localizedDescription]);
            self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\nError deleting file: %@", [error localizedDescription]]];
        } else {
            NSLog(@"File %@ deleted.", file);
            self.logTextView.text = [self.logTextView.text stringByAppendingString:[NSString stringWithFormat:@"\nFile %@ deleted.", file]];
        }
    }
}

- (IBAction)clearConsole:(id)sender
{
    self.logTextView.text = @"";
}

@end
