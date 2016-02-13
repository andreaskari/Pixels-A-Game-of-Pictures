//
//  Picture.m
//  PixelGun
//
//  Created by Andre Askarinam on 7/5/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Picture.h"

@implementation Picture

// For Pixel Container
static const CGFloat PIXEL_CONTAINER_WIDTH = 100;
static const CGFloat PIXEL_CONTAINER_HEIGHT = 100;
static const CGFloat DISTANCE_FROM_CONTAINER_WALLS = 5.0;

- (instancetype)initWithUIImage:(UIImage *)picture andGenerateShuffledPixels:(BOOL)generateShuffledPixels
{
    // Creates currentPicture, creates Pixels and gives each pixel a square, then updates the pixelContainer size
    self = [super init];
    if (self) {
        self.originalPicture = picture;
        [self getPictureDataWithPixelsLayout:generateShuffledPixels];
        
        if (generateShuffledPixels) {
            // Copies shuffled pixels then shuffles
            self.shuffledPixels = [NSMutableArray arrayWithArray:self.pixelsLayout];
            [self shufflePixelArray];
        }
    }
    return self;
}

- (void)getPictureDataWithPixelsLayout:(BOOL)generatePixelLayoutArray
{
    // Create a 1x1 pixel byte array and bitmap context to draw the pixel into.
    // Reference: https://github.com/ole/OBShapedButton/blob/master/UIImage%2BColorAtPixel/UIImage%2BColorAtPixel.m
    
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    
    CGImageRef cgImage = self.originalPicture.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger width = self.originalPicture.size.width;
    NSUInteger height = self.originalPicture.size.height;
    
    self.pixelsLayout = [NSMutableArray arrayWithCapacity:width*height];
    
    int actualHeight = 0;
    int actualWidth = 0;
    int lowestRow = (int) height;
    int lowestCol = (int) width;
    
    for (int row = 0; row < height; row++)
    {
        for (int col = 0; col < width; col++)
        {
            unsigned char pixelData[4] = { 0, 0, 0, 0 };
            
            CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            // Draw the pixel we are interested in onto the bitmap context
            CGContextTranslateCTM(context, -col, row-(CGFloat)height);
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
            CGContextRelease(context);
            
            // Convert color values [0..255] to floats [0.0..1.0]
            CGFloat red   = (CGFloat)pixelData[0] / 255.0;
            CGFloat green = (CGFloat)pixelData[1] / 255.0;
            CGFloat blue  = (CGFloat)pixelData[2] / 255.0;
            CGFloat alpha = (CGFloat)pixelData[3] / 255.0;
            
            if (alpha != 0) {
                if (generatePixelLayoutArray) {
                    Pixel *pixel = [[Pixel alloc] init];
                    
                    pixel.red = red;
                    pixel.blue = blue;
                    pixel.green = green;
                    
                    pixel.x = col;
                    pixel.y = row;
                    [self.pixelsLayout addObject:pixel];
                }
                
                if (col > actualWidth) {
                    actualWidth = col;
                }
                if (row > actualHeight) {
                    actualHeight = row;
                }
                if (col < lowestCol) {
                    lowestCol = col;
                }
                if (row < lowestRow) {
                    lowestRow = row;
                }
            }
        }
    }
    CGColorSpaceRelease(colorSpace);
    
    // Configure width/height of new pixel photo and reconfigure all xy-coordinates of each pixel
    self.width = actualWidth - (lowestCol - 1);
    self.height = actualHeight - (lowestRow - 1);
    for (int index = 0; index < [self.pixelsLayout count]; index++) {
        Pixel *currentPixel = [self.pixelsLayout objectAtIndex:index];
        currentPixel.x -= lowestCol;
        currentPixel.y -= lowestRow;
    }
    
    CGFloat pixelSizeForX = (PIXEL_CONTAINER_WIDTH - 2 * DISTANCE_FROM_CONTAINER_WALLS) / self.width;
    CGFloat pixelSizeForY = (PIXEL_CONTAINER_HEIGHT - 2 * DISTANCE_FROM_CONTAINER_WALLS) / self.height;
    if (pixelSizeForX > pixelSizeForY) {
        self.pixelSize = pixelSizeForY;
    } else {
        self.pixelSize = pixelSizeForX;
    }
}

- (void)shufflePixelArray
{
    NSUInteger count = [self.shuffledPixels count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((int) remainingCount);
        [self.shuffledPixels exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}

@end
