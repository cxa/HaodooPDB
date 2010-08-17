// Copyright (c) 2010, Chen Xian'an <xianan.chen@gmail.com>
// All rights reserved.

#import "NSString+HaodooPDB.h"

#define NEED_TO_REPLACE(c) (c == 0x2502 || (0xfe10 <= c && c <= 0xf18) || (0xfe35 <= c && c <= 0xfe44) || c == 0xff5c || c == 0xffe4)
#define ARRAY_LENGTH(array) (sizeof(array)/sizeof(array[0]))
#define IS_DOUBLE_VERTICAL_ELLIPSIS(c) (c == 0x2502 || c == 0xffe4)

static unichar vPuns[] = {0x2502, 0xfe10, 0xfe11, 0xfe12, 0xfe13, 0xfe14, 0xfe15, 0xfe16, 0xfe17, 0xfe18, 0xfe35, 0xfe36, 0xfe37, 0xfe38, 0xfe39, 0xfe3a, 0xfe3b, 0xfe3c, 0xfe3d, 0xfe3e, 0xfe3f, 0xfe40, 0xfe41, 0xfe42, 0xfe43, 0xfe44, 0xff5c, 0xffe4};      // │︐︑︒︓︔︕︖︗︘︵︶︹︺︷︸︻︼︽︾︿﹀﹁﹂﹃﹄｜￤
static unichar hPuns[] = {0x2026, 0xff0c, 0x3001, 0x3002, 0xff1a, 0xff1b, 0xff01, 0xff1f, 0x3016, 0x3017, 0xff08, 0xff09, 0xff58, 0xff5d, 0x3014, 0x3015, 0x3010, 0x3011, 0x300a, 0x300b, 0x3008, 0x3009, 0x300c, 0x300d, 0x300e, 0x300f, 0x2014, 0x2026};      // …，、。：；！？〖〗（）｛｝〔〕【】《》〈〉「」『 』—…

@implementation NSString(HaodooPDB)

- (NSString *)stringByReplacingVerticalPunctuations
{
  NSUInteger len = [self length];
  NSUInteger realLen = len+1;
  for (NSUInteger i=0; i<len; i++){
    if (IS_DOUBLE_VERTICAL_ELLIPSIS([self characterAtIndex:i])) realLen++;
  }
  
  unichar *chars = malloc(sizeof(unichar) * realLen);
  if (!chars) return nil;

  NSLog(@"len: %d, realLen:%d", len, realLen);
  
  chars[realLen] = '\0';
  NSUInteger punsLen = ARRAY_LENGTH(vPuns);
  for (NSUInteger i=0, j=0; i<len; i++, j++){
    unichar c = [self characterAtIndex:i];
    unichar r = c;
    if (NEED_TO_REPLACE(c)){
      NSUInteger low = 0;
      NSUInteger mid = 0;
      NSUInteger high = punsLen - 1;

      while (low <= high){      // binary search
        mid = (low + high) / 2;
        if (c < vPuns[mid]){
          high = mid - 1;
        } else if (c > vPuns[mid]){
          low = mid + 1;
        } else {
          break;
        }
      }

      r = hPuns[mid];
      if (IS_DOUBLE_VERTICAL_ELLIPSIS(c)){
        chars[j] = r;
        j++;
      }
    }
    
    chars[j] = r;
  }
  
  NSString *str = [[NSString alloc] initWithCharacters:chars length:realLen];
  free(chars);
  
  return [str autorelease];
}

@end
