// Copyright (c) 2010, Chen Xian'an <xianan.chen@gmail.com>
// All rights reserved.
// Haodoo PDB spec：http://haodoo.net/?M=hd&P=mPDB22

#import "HaodooPDB.h"

#define PDBHEADER_LENGTH 78
#define PDBTYPE_POSITION 64
#define PDBAUTHOR_POSITION 34
#define PDBNUMCHAPTERS_POSITION 76
#define PDBRECORD_ENTRY_SIZE 8
#define ESC_UNICODE ('\e' << 8)
#define ESC_ASCII '\e'
#define NULLCHAR '\0'

@interface HaodooPDB()
- (NSData *)dataWithRecordIndex:(NSUInteger)index;
@end

@implementation HaodooPDB
@synthesize type;

- (id)initWithFile:(NSString *)aFilePath
{
  return [self initWithFile:aFilePath error:nil];
}

- (id)initWithFile:(NSString *)aFilePath
             error:(NSError **)error
{
  if (self = [super init]){
    filePath = [aFilePath copy];
    fileHandle = [[NSFileHandle fileHandleForReadingAtPath:filePath] retain];
    if (fileHandle){
      [fileHandle seekToFileOffset:PDBTYPE_POSITION];
      NSData *data = [fileHandle readDataOfLength:4];
      type = OSReadBigInt32([data bytes], 0);
      textEncoding  = type == BOOKTYPE_MTIU 
        ? NSUTF16LittleEndianStringEncoding
        : CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5);
      
      [fileHandle seekToFileOffset:PDBNUMCHAPTERS_POSITION];
      data = [fileHandle readDataOfLength:2];
      numRecords = (NSUInteger)OSReadBigInt16([data bytes], 0);
    } else if (error != NULL){
      *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:[NSDictionary dictionaryWithObject:filePath forKey:@"filePath"]];
    }
  }

  return self;
}

- (void)dealloc
{
  [filePath release];
  [fileHandle release];
  
  [super dealloc];
}

- (NSString *)title
{
  if (!fileHandle) return nil;

  NSData *data = [self dataWithRecordIndex:0];
  UInt8 *bytes = (UInt8 *)[data bytes];
  UInt32 offsetStart = 8;      // 参看 Haodoo PDB 规格，前八字符为空白
  UInt32 offsetEnd = offsetStart;
  
  if (type == BOOKTYPE_MTIU)
    while (OSReadBigInt16(bytes, offsetEnd) != ESC_UNICODE) offsetEnd += 2;
  else 
    while (bytes[offsetEnd] != ESC_ASCII) offsetEnd++;
  
  return [[[NSString alloc] initWithBytes:&bytes[offsetStart] length:offsetEnd-offsetStart encoding:textEncoding] autorelease];
}

- (NSString *)author
{
  // 只有 MTIU 才有作者资料
  if (!fileHandle || type != BOOKTYPE_MTIU) return nil;

  [fileHandle seekToFileOffset:0];
  NSData *data = [fileHandle readDataOfLength:PDBAUTHOR_POSITION];
  
  return [[[NSString alloc] initWithData:data encoding:textEncoding] autorelease];
}

- (NSArray *)chapters
{
  if (!fileHandle) return nil;
  
  NSData *data = [self dataWithRecordIndex:0];
  UInt8 *bytes = (UInt8 *)[data bytes];
  UInt32 offsetStart = 8;      // 参看 Haodoo PDB 规格，前八字符为空白
  UInt32 offsetEnd = offsetStart;
  if (type == BOOKTYPE_MTIU){
    while (OSReadBigInt16(bytes, offsetStart) != ESC_UNICODE) offsetStart += 2;
    offsetStart += 3*2;
    offsetEnd = offsetStart;
    while (OSReadBigInt16(bytes, offsetEnd) != ESC_UNICODE) offsetEnd += 2;
  } else {
    while (bytes[offsetStart] != ESC_ASCII) offsetStart++;
    offsetStart += 3;
    offsetEnd = offsetStart;
    while (bytes[offsetEnd] != ESC_ASCII) offsetEnd++;
  }
  
  long numChapters = strtol((const char *)&bytes[offsetStart], NULL, 10);

  if (numChapters < 1) return nil;
  
  NSString *separator;
  if (type == BOOKTYPE_MTIU){
    offsetStart = offsetEnd+2;
    separator = @"\r\n";
  } else {
    offsetStart = offsetEnd+1;
    separator = @"\e";
  }
  
  offsetEnd = [data length];
  NSString *str = [[NSString alloc] initWithBytes:&bytes[offsetStart] length:offsetEnd-offsetStart encoding:textEncoding];
  NSArray *chaps = [str componentsSeparatedByString:separator];
  [str release];

  return chaps;
}

- (NSString *)contentAtChapter:(NSUInteger)index
{
  if (!fileHandle) return nil;

  NSData *data = [self dataWithRecordIndex:(index+1)];

  return [[[NSString alloc] initWithData:data encoding:textEncoding] autorelease];
}

- (NSString *)stringByReplacingVerticalPunctuations
{
  
}

#pragma mark -
#pragma mark Private methods
- (NSData *)dataWithRecordIndex:(NSUInteger)index
{
  [fileHandle seekToFileOffset:PDBHEADER_LENGTH + PDBRECORD_ENTRY_SIZE*index];
  NSData *data = [fileHandle readDataOfLength:4];
  UInt32 offset = OSReadBigInt32([data bytes], 0);
  
  if (index == numRecords-1){
    [fileHandle seekToFileOffset:offset];
    return [fileHandle readDataToEndOfFile];
  }

  [fileHandle seekToFileOffset:PDBHEADER_LENGTH + PDBRECORD_ENTRY_SIZE*(index+1)];
  data = [fileHandle readDataOfLength:4];
  UInt32 nextOffset = OSReadBigInt32([data bytes], 0);
  [fileHandle seekToFileOffset:offset];
  
  return [fileHandle readDataOfLength:nextOffset-offset];
}

@end
