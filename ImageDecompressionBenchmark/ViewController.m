//
//  ViewController.m
//  ImageDecompressionBenchmark
//
//  Created by Konstantin Käfer on 19.01.2016.
//  Copyright © 2016 mapbox. All rights reserved.
//

#import "ViewController.h"

#import <ImageIO/ImageIO.h>

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#include <webp/decode.h>

extern uint64_t dispatch_benchmark(size_t count, void (^block)(void));

@interface ViewController ()

@end

@implementation ViewController

- (void)decodeImage:(CFDataRef)data {
    CGImageSourceRef image_source = CGImageSourceCreateWithData(data, NULL);
    if (!image_source) {
        NSLog(@"CGImageSourceCreateWithData failed");
        return;
    }

    CGImageRef image = CGImageSourceCreateImageAtIndex(image_source, 0, NULL);
    if (!image) {
        CFRelease(image_source);
        NSLog(@"CGImageSourceCreateImageAtIndex failed");
        return;
    }

    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    if (!color_space) {
        CGImageRelease(image);
        CFRelease(image_source);
        NSLog(@"CGColorSpaceCreateDeviceRGB failed");
        return;
    }

    const size_t width = CGImageGetWidth(image);
    const size_t height = CGImageGetHeight(image);
    const size_t stride = width * 4;
    const size_t size = width * height * 4;
    uint8_t* result = malloc(size);

    CGContextRef context = CGBitmapContextCreate(result, width, height, 8, stride, color_space, kCGImageAlphaPremultipliedLast);
    if (!context) {
        CGColorSpaceRelease(color_space);
        CGImageRelease(image);
        CFRelease(image_source);
        free(result);
        NSLog(@"CGBitmapContextCreate failed");
        return;
    }

    CGContextSetBlendMode(context, kCGBlendModeCopy);

    CGRect rect = {{ 0, 0 }, { (CGFloat)width, (CGFloat)height }};
    CGContextDrawImage(context, rect, image);

    CGContextRelease(context);
    CGColorSpaceRelease(color_space);
    CGImageRelease(image);
    CFRelease(image_source);
    free(result);
}

- (void)decodeWebP:(CFDataRef)data {
    int width = 0, height = 0;
    uint8_t *result = WebPDecodeRGBA(CFDataGetBytePtr(data), CFDataGetLength(data), &width, &height);
    if (!result) {
        NSLog(@"WebPDecodeRGBA failed");
        return;
    }
    free(result);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)decodePNG {
    // Load PNG into memory
    NSString *path = [[NSBundle mainBundle] pathForResource:@"images/17-20969-50662" ofType:@"png"];
    NSData *data = [NSData dataWithContentsOfFile: path];
    CFDataRef image = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, [data bytes], [data length], kCFAllocatorNull);

    uint64_t duration = dispatch_benchmark(1000, ^{
        @autoreleasepool {
            [self decodeImage:image];
        }
    });
    NSLog(@"PNG: avg=%.3f ms", (double)duration / 1000000);
}

- (IBAction)decodeJPEG {
    // Load JPEG into memory
    NSString *path = [[NSBundle mainBundle] pathForResource:@"images/17-20969-50662" ofType:@"jpg"];
    NSData *data = [NSData dataWithContentsOfFile: path];
    CFDataRef image = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, [data bytes], [data length], kCFAllocatorNull);

    uint64_t duration = dispatch_benchmark(1000, ^{
        @autoreleasepool {
            [self decodeImage:image];
        }
    });
    NSLog(@"JPEG: avg=%.3f ms", (double)duration / 1000000);
}

- (IBAction)decodeWebP {
    // Load JPEG into memory
    NSString *path = [[NSBundle mainBundle] pathForResource:@"images/17-20969-50662" ofType:@"webp"];
    NSData *data = [NSData dataWithContentsOfFile: path];
    CFDataRef image = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, [data bytes], [data length], kCFAllocatorNull);

    uint64_t duration = dispatch_benchmark(1000, ^{
        @autoreleasepool {
            [self decodeWebP:image];
        }
    });
    NSLog(@"WebP: avg=%.3f ms", (double)duration / 1000000);
}

@end
