# ADBDownloadManager

A download manager for iOS. Actually, all that you need to download files without any external library.

Simple usage:

- copy ADBDownloadManager class into your project
- import `ADBDownloadManager.h` in your class
- use as follow

``` objective-c
NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
self.downloadManager = [[ADBDownloadManager alloc] initWithBaseRemoteURL:@"http://www.myservice.com/"
                                                         localPathFolder:documentsDirectory
                                                                   queue:[NSOperationQueue currentQueue]];
        
self.downloadManager.delegate = self;
self.downloadManager.dataSource = self;

[self.downloadManager start];
```

- implement the  ADBDownloadManagerDataSource protocol

``` objective-c
#pragma mark - ADBDownloadManagerDataSource

- (NSUInteger)numberOfFilesToDownloadForDownloadManager:(ADBDownloadManager *)manager { ... }

- (NSString *)downloadManager:(ADBDownloadManager *)manager
 pathForFileToDownloadAtIndex:(NSUInteger)index { ... }

```

- implement the ADBDownloadManagerDelegate protocol

``` objective-c
#pragma mark - ADBDownloadManagerDataSource

- (void)downloadManager:(ADBDownloadManager *)manager
 didDownloadFileAtIndex:(NSUInteger)index
          fromRemoteURL:(NSString *)remoteURL
            toLocalPath:(NSString *)localPath
                  bytes:(NSUInteger)bytes { ... }

- (void)downloadManager:(ADBDownloadManager *)manager
     didFailFileAtIndex:(NSUInteger)index
          fromRemoteURL:(NSString *)remoteURL
            toLocalPath:(NSString *)localPath
                  error:(NSError *)error { ... }

- (void)downloadManagerDidCompleteAllDownloads:(ADBDownloadManager *)manager
                                    failedURLs:(NSArray *)failedURLs
                                    totalBytes:(NSUInteger)totalBytes { ... }

- (void)downloadManagerWillStart:(ADBDownloadManager *)manager { ... }

- (void)downloadManagerDidStop:(ADBDownloadManager *)manager { ... }
```

There you go.

# License

Licensed under the New BSD License.

Copyright (c) 2012, Alberto De Bortoli
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Alberto De Bortoli nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Alberto De Bortoli BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Resources

Info can be found on [my website](http://www.albertodebortoli.it), [and on Twitter](http://twitter.com/albertodebo).
