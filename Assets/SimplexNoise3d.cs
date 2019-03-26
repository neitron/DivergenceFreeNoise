//
// This code is based on the webgl-noise GLSL shader. For further details
// of the original shader, please see the following description from the
// original source code.
//

//
// Description : Array and textureless GLSL 2D/3D/4D simplex
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//

using UnityEngine;
using Unity.Mathematics;


class SimplexNoise3d
{


    private static float3 mod289(float3 x)
    {
        return x - math.floor(x / 289.0f) * 289.0f;
    }


    private static float4 mod289(float4 x)
    {
        return x - math.floor(x / 289.0f) * 289.0f;
    }


    private static float4 permute(float4 x)
    {
        return mod289((x * 34.0f + 1.0f) * x);
    }


    private static float4 taylorInvSqrt(float4 r)
    {
        return 1.79284291400159f - r * 0.85373472095314f;
    }


    public static float4 snoise(float3 v)
    {
        float2 c = new float2(1.0f / 6.0f, 1.0f / 3.0f);

        // First corner
        float3 i = math.floor(v + math.dot(v, c.yyy));
        float3 x0 = v - i + math.dot(i, c.xxx);

        // Other corners
        float3 g = math.step(x0.yzx, x0.xyz);
        float3 l = 1.0f - g;
        float3 i1 = math.min(g.xyz, l.zxy);
        float3 i2 = math.max(g.xyz, l.zxy);

        // x1 = x0 - i1  + 1.0 * C.xxx;
        // x2 = x0 - i2  + 2.0 * C.xxx;
        // x3 = x0 - 1.0 + 3.0 * C.xxx;
        float3 x1 = x0 - i1 + c.xxx;
        float3 x2 = x0 - i2 + c.yyy;
        float3 x3 = x0 - 0.5f;

        // Permutations
        i = mod289(i); // Avoid truncation effects in permutation
        float4 p =
          permute(permute(permute(i.z + new float4(0.0f, i1.z, i2.z, 1.0f))
                                + i.y + new float4(0.0f, i1.y, i2.y, 1.0f))
                                + i.x + new float4(0.0f, i1.x, i2.x, 1.0f));

        // Gradients: 7x7 points over a square, mapped onto an octahedron.
        // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
        float4 j = p - 49.0f * math.floor(p / 49.0f);  // mod(p,7*7)

        float4 x_ = math.floor(j / 7.0f);
        float4 y_ = math.floor(j - 7.0f * x_);  // mod(j,N)

        float4 x = (x_ * 2.0f + 0.5f) / 7.0f - 1.0f;
        float4 y = (y_ * 2.0f + 0.5f) / 7.0f - 1.0f;

        float4 h = 1.0f - math.abs(x) - math.abs(y);

        float4 b0 = new float4(x.xy, y.xy);
        float4 b1 = new float4(x.zw, y.zw);

        //float4 s0 = float4(lessThan(b0, 0.0)) * 2.0 - 1.0;
        //float4 s1 = float4(lessThan(b1, 0.0)) * 2.0 - 1.0;
        float4 s0 = math.floor(b0) * 2.0f + 1.0f;
        float4 s1 = math.floor(b1) * 2.0f + 1.0f;
        float4 sh = -math.step(h, 0.0f);

        float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
        float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

        float3 g0 = new float3(a0.xy, h.x);
        float3 g1 = new float3(a0.zw, h.y);
        float3 g2 = new float3(a1.xy, h.z);
        float3 g3 = new float3(a1.zw, h.w);

        // Normalize gradients
        float4 norm = taylorInvSqrt(new float4(math.dot(g0, g0), math.dot(g1, g1), math.dot(g2, g2), math.dot(g3, g3)));
        g0 *= norm.x;
        g1 *= norm.y;
        g2 *= norm.z;
        g3 *= norm.w;

        // Compute noise and gradient at P
        float4 m = math.max(0.6f - new float4(math.dot(x0, x0), math.dot(x1, x1), math.dot(x2, x2), math.dot(x3, x3)), 0.0f);
        float4 m2 = m * m;
        float4 m3 = m2 * m;
        float4 m4 = m2 * m2;
        float3 grad =
          -6.0f * m3.x * x0 * math.dot(x0, g0) + m4.x * g0 +
          -6.0f * m3.y * x1 * math.dot(x1, g1) + m4.y * g1 +
          -6.0f * m3.z * x2 * math.dot(x2, g2) + m4.z * g2 +
          -6.0f * m3.w * x3 * math.dot(x3, g3) + m4.w * g3;
        float4 px = new float4(math.dot(x0, g0), math.dot(x1, g1), math.dot(x2, g2), math.dot(x3, g3));
        return 42.0f * new float4(grad, math.dot(m4, px));
    }
}