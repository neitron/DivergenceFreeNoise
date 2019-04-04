Shader "Neitron/RayMarch/Spiral Sphere Surf"
{
    Properties
    {
		_Settings("Max Ray Steps, MinDistance, Radius, Smooth", Vector) = (10.0, 1.0, 1.0, 0.0)
		_ExtraSettings("Twist, Frequency, Amplitude, Speed", Vector) = (5.0, 10.0, 0.05, 1.0)
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		[HDR]_RimColor("RimColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_RimPower("RimPower", Float) = 0.2
    }
    SubShader
    {
		Tags {"Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 200
		Cull Off

        CGPROGRAM
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 5.0
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows alpha:fade
		
		#include "UnityCG.cginc"

		#include "../Cg/Helpers.cginc"
		#include "RayMarch.cginc"





        sampler2D _MainTex;
		
		#ifdef SHADER_API_D3D11
			StructuredBuffer<float3> PositionsBuffer; // this actually works after all!      
			StructuredBuffer<float2> ScaleBuffer; // this actually works after all!
		#endif
        
		struct Input
        {
            float2 uv_MainTex;
			float3 viewDir;
        };

		float _Smoothness;
		float _Metallic;
		fixed4 _RimColor;
		float _RimPower;
		float4 _ExtraSettings;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)


		float dropSetOf8()
		{
		
		}

		float dropSetOf16(float3 p, int i)
		{
			float scene = 999999999; //sphereSDF(p, 0.1f);
			
			#ifdef SHADER_API_D3D11
			
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[0 + i],  ScaleBuffer[0 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[1 + i],  ScaleBuffer[1 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[2 + i],  ScaleBuffer[2 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[3 + i],  ScaleBuffer[3 + i].x), _Settings.w);
														  					 
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[4 + i],  ScaleBuffer[4 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[5 + i],  ScaleBuffer[5 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[6 + i],  ScaleBuffer[6 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[7 + i],  ScaleBuffer[7 + i].x), _Settings.w);
																			 
				// 8														 
																			 
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[8 + i],  ScaleBuffer[8 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[9 + i],  ScaleBuffer[9 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[10 + i], ScaleBuffer[10 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[11 + i], ScaleBuffer[11 + i].x), _Settings.w);
																			  
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[12 + i], ScaleBuffer[12 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[13 + i], ScaleBuffer[13 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[14 + i], ScaleBuffer[14 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[15 + i], ScaleBuffer[15 + i].x), _Settings.w);
																			  
				// 16														  
																			  
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[16 + i], ScaleBuffer[16 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[17 + i], ScaleBuffer[17 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[18 + i], ScaleBuffer[18 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[19 + i], ScaleBuffer[19 + i].x), _Settings.w);
														  					  
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[20 + i], ScaleBuffer[20 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[21 + i], ScaleBuffer[21 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[22 + i], ScaleBuffer[22 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[23 + i], ScaleBuffer[23 + i].x), _Settings.w);
																			  
				// 24														  
																			  
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[24 + i], ScaleBuffer[24 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[25 + i], ScaleBuffer[25 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[26 + i], ScaleBuffer[26 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[27 + i], ScaleBuffer[27 + i].x), _Settings.w);
																			  
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[28 + i], ScaleBuffer[28 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[29 + i], ScaleBuffer[29 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[30 + i], ScaleBuffer[30 + i].x), _Settings.w);
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[31 + i], ScaleBuffer[31 + i].x), _Settings.w);
			
				// 32

			#endif

			return scene;
		}


		float HavyScene(float3 p)
		{
			float scene = 999999999; //sphereSDF(p, 0.1f);
			
			#ifdef SHADER_API_D3D11

			uint count;
			uint stride;

			PositionsBuffer.GetDimensions(count, stride);

			int i;
			for(i = 0; i < count; i++)
			{
				scene = opSmoothUnion(scene, sphereSDF(p + PositionsBuffer[i], ScaleBuffer[i].x), _Settings.w);
			}	
			#endif

			return scene;
		}


		float3 mod(float3 a, float3 b)
		{
			return frac(abs(a / b)) * abs(b);
		}


		float sceneSDF(float3 p)
		{
			// I might try to use some repetion technik here 
			//return dropSetOf16(p, 0);
			return min(dropSetOf16(p, 0), dropSetOf16(p, 32));
			//return HavyScene(p);
		}


		float trace(float3 from, float3 direction, out float3 p)
		{
			float totalDistance = 0.0f;
			int steps;
			float distance; 
			for (steps = 0; steps < _Settings.x; steps++)
			{
				p = from + totalDistance * direction;
				distance = sceneSDF(p);
				totalDistance += distance;

				if (distance < _Settings.y)
				{
					break;
				}
			}
			return 1.0f - float(steps) / float(_Settings.x);
		}


		static const float3 xDir = float3(_Settings.y, 0.0f, 0.0f);
		static const float3 yDir = float3(0.0f, _Settings.y, 0.0f);
		static const float3 zDir = float3(0.0f, 0.0f, _Settings.y);
			

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float3 p; // closest point
			float3 viewDir = normalize(-IN.viewDir);
			float res = trace(_WorldSpaceCameraPos, -viewDir, p);

            // Albedo comes from a texture tinted by color
            //fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			fixed3 finalColor = _Color.rgb * res;
            o.Albedo = finalColor;
            o.Alpha = step(length(p), 200) * _Color.a;
            
			//xDir = float3(_Settings.y, 0.0f, 0.0f);
			//yDir = float3(0.0f, _Settings.y, 0.0f);
			//zDir = float3(0.0f, 0.0f, _Settings.y);
			
			float3 norm = normalize(float3(
				sceneSDF(p + xDir) - sceneSDF(p - xDir),
				sceneSDF(p + yDir) - sceneSDF(p - yDir),
				sceneSDF(p + zDir) - sceneSDF(p - zDir)));
			
			o.Normal = norm;
			
			// Rim
			half rim = 1.0 - saturate(dot(viewDir, o	.Normal));
			o.Emission = _RimColor.rgb * pow(rim, _RimPower);

			// Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
