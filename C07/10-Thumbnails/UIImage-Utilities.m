/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 5.x Edition
 BSD License, Use at your own risk
 */


#import "UIImage-Utilities.h"
#import "Geometry.h"

NSUInteger alphaOffset(NSUInteger x, NSUInteger y, NSUInteger w)
{return y * w * 4 + x * 4 + 0;}
NSUInteger redOffset(NSUInteger x, NSUInteger y, NSUInteger w)
{return y * w * 4 + x * 4 + 1;}
NSUInteger greenOffset(NSUInteger x, NSUInteger y, NSUInteger w)
{return y * w * 4 + x * 4 + 2;}
NSUInteger blueOffset(NSUInteger x, NSUInteger y, NSUInteger w)
{return y * w * 4 + x * 4 + 3;}

CIImage *ciImageFromPNG(NSString *pngFileName)
{
    UIImage *pngImage = [UIImage imageNamed:pngFileName];
    NSData *data = UIImageJPEGRepresentation(pngImage, 1.0f);
    UIImage *jpegImage = [[UIImage alloc] initWithData:data];    
    
    return [CIImage imageWithCGImage:jpegImage.CGImage];
}

UIImage *imageFromView(UIView *theView)
{
	UIGraphicsBeginImageContext(theView.frame.size);
	[theView.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

UIImage *screenShot()
{
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	return imageFromView(window);
}

@implementation UIImage (Utilities)
+ (UIImage *) imageWithCIImage: (CIImage *) aCIImage orientation: (UIImageOrientation) anOrientation
{
    if (!aCIImage) return nil;
    
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:aCIImage fromRect:aCIImage.extent];
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0f orientation:anOrientation];
    CFRelease(cgImage);
    
    return image;
}

+ (UIImage *) imageWithBits: (UInt8 *) bits withSize: (CGSize) size
{
	// 建立色彩空間
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
		free(bits);
        return nil;
    }
	
	// 建立點陣圖內文
    CGContextRef context = CGBitmapContextCreate (bits, size.width, size.height, 8, size.width * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        fprintf (stderr, "Error: Context not created!");
        free (bits);
		CGColorSpaceRelease(colorSpace );
		return nil;
    }
	
	// 建立CGImageRef
    CGColorSpaceRelease(colorSpace );
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	free(CGBitmapContextGetData(context)); // This does the free
	CGContextRelease(context);
	
	// 利用CGImageRef回傳UIImage
	UIImage *newImage = [UIImage imageWithCGImage:imageRef];
	CFRelease(imageRef);

	return newImage;
}

// 等比例縮放，完整置入視圖裡，不裁切
- (UIImage *) fitInSize: (CGSize) viewsize
{
    // 計算置入時的大小
    CGSize size = CGSizeFitInSize(self.size, viewsize);
    
    UIGraphicsBeginImageContext(viewsize);
    
    // 計算需要鋪上多少空白
    float dwidth = (viewsize.width - size.width) / 2.0f;
    float dheight = (viewsize.height - size.height) / 2.0f;
    
    CGRect rect = CGRectMake(dwidth, dheight, size.width, size.height);
    [self drawInRect:rect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

// 不縮放，可能會裁切
- (UIImage *) centerInSize: (CGSize) viewsize
{
    CGSize size = self.size;
    UIGraphicsBeginImageContext(viewsize);
    
    // 計算偏移值，確定讓圖像的中心
    // 放在視圖的中心
    float dwidth = (viewsize.width - size.width) / 2.0f;
    float dheight = (viewsize.height - size.height) / 2.0f;
    
    CGRect rect = CGRectMake(dwidth, dheight, size.width, size.height);
    [self drawInRect:rect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

// 填滿視圖每一個像素，邊緣不留白,
// 若需要，縮放並裁切
- (UIImage *) fillSize: (CGSize) viewsize
{
    CGSize size = self.size;
    
    // 決定最小的縮放比例
    CGFloat scalex = viewsize.width / size.width;
    CGFloat scaley = viewsize.height / size.height;
    CGFloat scale = MAX(scalex, scaley);
    
    UIGraphicsBeginImageContext(viewsize);
    
    CGFloat width = size.width * scale;
    CGFloat height = size.height * scale;
    
    // 縮放後，將圖像置中
    float dwidth = ((viewsize.width - width) / 2.0f);
    float dheight = ((viewsize.height - height) / 2.0f);
    
    CGRect rect = CGRectMake(dwidth, dheight, size.width * scale, size.height * scale);
    [self drawInRect:rect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *) subImageWithBounds:(CGRect) rect
{
    UIGraphicsBeginImageContext(rect.size);
    
    CGRect destRect = CGRectMake(-rect.origin.x, -rect.origin.y, self.size.width, self.size.height);
    [self drawInRect:destRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

CGContextRef CreateARGBBitmapContext (CGSize size)
{
    // 建立新的色彩空間
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // 配置記憶體存放點陣圖資料
    void *bitmapData = malloc(size.width * size.height * 4);
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Error: Memory not allocated!");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    // 建立內文，一個色頻有8 bits
    CGContextRef context = CGBitmapContextCreate (bitmapData, size.width, size.height, 8, size.width * 4, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace );
    if (context == NULL)
    {
        fprintf (stderr, "Error: Context not created!");
        free (bitmapData);
        return NULL;
    }
    
    return context;
}

- (UInt8 *) createBitmap
{
    // 給定某圖像，建立點陣圖資料
    CGContextRef context = CreateARGBBitmapContext(self.size);
    if (context == NULL) return NULL;
    
    CGRect rect = CGRectMake(0.0f, 0.0f, self.size.width, self.size.height);
    CGContextDrawImage(context, rect, self.CGImage);
    UInt8 *data = CGBitmapContextGetData(context);
    CGContextRelease(context);
    
    return data;
}

- (UIImage *) convolveImageWithEdgeDetection
{
    // 維度
    int theheight = floor(self.size.height);
    int thewidth =  floor(self.size.width);
    
    // 取得輸入bits，建立輸出bits
    UInt8 *inbits = (UInt8 *)[self createBitmap];
    UInt8 *outbits = (UInt8 *)malloc(theheight * thewidth * 4);
    
    // 基本的Canny邊緣偵測
    int matrix1[9] = {-1, 0, 1, -2, 0, 2, -1, 0, 1};
    int matrix2[9] = {-1, -2, -1, 0, 0, 0, 1, 2, 1};
    
    int radius = 1;
    
    // 迭代每個像素（留下寬radius的邊界)
    for (int y = radius; y < (theheight - radius); y++)
        for (int x = radius; x < (thewidth - radius); x++)
        {
            int sumr1 = 0, sumr2 = 0;
            int sumg1 = 0, sumg2 = 0;
            int sumb1 = 0, sumb2 = 0;
            int offset = 0;
            for (int j = -radius; j <= radius; j++)
                for (int i = -radius; i <= radius; i++)
                {
                    sumr1 += inbits[redOffset(x+i, y+j, thewidth)] *
                    matrix1[offset];
                    sumr2 += inbits[redOffset(x+i, y+j, thewidth)] *
                    matrix2[offset];
                    
                    sumg1 += inbits[greenOffset(x+i, y+j, thewidth)] *
                    matrix1[offset];
                    sumg2 += inbits[greenOffset(x+i, y+j, thewidth)] *
                    matrix2[offset];
                    
                    sumb1 += inbits[blueOffset(x+i, y+j, thewidth)] *
                    matrix1[offset];
                    sumb2 += inbits[blueOffset(x+i, y+j, thewidth)] *
                    matrix2[offset];
                    offset++;
                }
            
            // 賦值outbits
            int sumr = MIN(((ABS(sumr1) + ABS(sumr2)) / 2), 255);
            int sumg = MIN(((ABS(sumg1) + ABS(sumg2)) / 2), 255);
            int sumb = MIN(((ABS(sumb1) + ABS(sumb2)) / 2), 255);
            
            outbits[redOffset(x, y, thewidth)] = (UInt8) sumr;
            outbits[greenOffset(x, y, thewidth)] = (UInt8)
            sumg;
            outbits[blueOffset(x, y, thewidth)] = (UInt8) sumb;
            outbits[alphaOffset(x, y, thewidth)] =
            (UInt8) inbits[alphaOffset(x, y, thewidth)];
        }
    
    // 釋放原先的點陣圖，imageWithBits釋放outbits
    free(inbits);

    return [UIImage imageWithBits:outbits withSize:CGSizeMake(thewidth, theheight)];
}
@end
