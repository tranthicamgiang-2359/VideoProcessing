//
//  ColorKernel.metal
//  VideoProcessing
//
//  Created by Tran Thi Cam Giang on 3/4/20.
//  Copyright © 2020 Tran Thi Cam Giang. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void fading(texture2d<float, access::read> inTexture1 [[texture(0)]],
                   texture2d<float, access::read> inTexture2 [[texture(1)]],
                   texture2d<float, access::write> outTexture [[texture(2)]],
                   constant float &firstVidRemainTime [[buffer(0)]],
                   constant bool &firstVidIsNill [[buffer(1)]],
                   constant bool &secondVidIsNill [[buffer(2)]],
                   constant float &overlapDuration [[buffer(3)]],
                   uint2 gid [[thread_position_in_grid]]) {
    float4 inColor1;
    float4 inColor2;
    
    if (secondVidIsNill) {
        inColor1 = inTexture1.read(gid);
        outTexture.write(inColor1, gid);
    } else if (firstVidIsNill) {
        inColor2 = inTexture2.read(gid);
        outTexture.write(inColor2, gid);
    } else {
        inColor1 = inTexture1.read(gid);
        inColor2 = inTexture2.read(gid);

        float w0 = firstVidRemainTime / overlapDuration;
        if (w0 > 1) {
            w0 = 1;
        }
        
        float w1 = 1 - w0;
        float4 newColor = w0 * inColor1 + w1 * inColor2;
        outTexture.write(newColor, gid);
    }
    
}

kernel void gaussian_blur(texture2d<float, access::read> inTexture [[texture(2)]],
                          texture2d<float, access::write> outTexture [[texture(3)]],
                          texture2d<float, access::read> weights [[texture(4)]],
                          constant bool &firstVidIsNill [[buffer(1)]],
                          constant bool &secondVidIsNill [[buffer(2)]],
                          uint2 gid [[thread_position_in_grid]])
{
    if (firstVidIsNill || secondVidIsNill) {
        float4 orig = inTexture.read(gid);
        outTexture.write(orig, gid);
        
    } else {
        int size = weights.get_width();
           int radius = size / 2;
        
           float4 accumColor(0, 0, 0, 0);
           for (int j = 0; j < size; ++j)
           {
               for (int i = 0; i < size; ++i)
               {
                   uint2 kernelIndex(i, j);
                   uint2 textureIndex(gid.x + (i - radius), gid.y + (j - radius));
                   float4 color = inTexture.read(textureIndex).rgba;
                   float4 weight = weights.read(kernelIndex).rrrr;
                   accumColor += weight * color;
               }
           }
        
           outTexture.write(float4(accumColor.rgb, 1), gid);
    }
    
}
