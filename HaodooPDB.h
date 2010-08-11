// Copyright (c) 2010, Chen Xian'an <xianan.chen@gmail.com>
// All rights reserved.

#import <Foundation/Foundation.h>

typedef enum {
  BOOKTYPE_UNKNOWN = 0,
  BOOKTYPE_MTIT = 'MTIT',
  BOOKTYPE_MTIU = 'MTIU',
} HaodooPDBType;

@interface HaodooPDB : NSObject {
  HaodooPDBType type;

  NSString *filePath;
  NSFileHandle *fileHandle;
  NSUInteger numRecords;
  NSStringEncoding textEncoding;
}

@property (nonatomic, readonly) HaodooPDBType type;
@property (nonatomic, retain, readonly) NSString *title;
@property (nonatomic, retain, readonly) NSString *author;
@property (nonatomic, retain, readonly) NSArray *chapters;

- (id)initWithFile:(NSString *)filePath;
- (id)initWithFile:(NSString *)filePath error:(NSError **)error;
- (NSString *)chapterContentAtIndex:(NSUInteger)index;

@end
