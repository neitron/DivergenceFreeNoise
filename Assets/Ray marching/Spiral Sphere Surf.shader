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
			//uniform RWStructuredBuffer<float2> ScaleBuffer;
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


		float dropSetOf16(float3 p)
		{
			float scene = 999999999; //sphereSDF(p, 0.1f);
			
			#ifdef SHADER_API_D3D11
			
				float3 pos = p + PositionsBuffer[0];
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[0].x), _Settings.w);
				pos = p + PositionsBuffer[1];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[1].x), _Settings.w);
				pos = p + PositionsBuffer[2];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[2].x), _Settings.w);
				pos = p + PositionsBuffer[3];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[3].x), _Settings.w);
														  
				pos = p + PositionsBuffer[4];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[4].x), _Settings.w);
				pos = p + PositionsBuffer[5];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[5].x), _Settings.w);
				pos = p + PositionsBuffer[6];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[6].x), _Settings.w);
				pos = p + PositionsBuffer[7];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[7].x), _Settings.w);
			
				// 8

				pos = p + PositionsBuffer[8];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[8].x), _Settings.w);
				pos = p + PositionsBuffer[9];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[9].x), _Settings.w);
				pos = p + PositionsBuffer[10];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[10].x), _Settings.w);
				pos = p + PositionsBuffer[11];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[11].x), _Settings.w);
			
				pos = p + PositionsBuffer[12];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[12].x), _Settings.w);
				pos = p + PositionsBuffer[13];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[13].x), _Settings.w);
				pos = p + PositionsBuffer[14];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[14].x), _Settings.w);
				pos = p + PositionsBuffer[15];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[15].x), _Settings.w);
			
				// 16

				pos = p + PositionsBuffer[16];
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[0].x), _Settings.w);
				pos = p + PositionsBuffer[17];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[1].x), _Settings.w);
				pos = p + PositionsBuffer[18];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[2].x), _Settings.w);
				pos = p + PositionsBuffer[19];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[3].x), _Settings.w);
														  
				pos = p + PositionsBuffer[20];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[4].x), _Settings.w);
				pos = p + PositionsBuffer[21];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[5].x), _Settings.w);
				pos = p + PositionsBuffer[22];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[6].x), _Settings.w);
				pos = p + PositionsBuffer[23];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[7].x), _Settings.w);
			
				// 24

				pos = p + PositionsBuffer[24];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[8].x), _Settings.w);
				pos = p + PositionsBuffer[25];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[9].x), _Settings.w);
				pos = p + PositionsBuffer[26];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[10].x), _Settings.w);
				pos = p + PositionsBuffer[27];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[11].x), _Settings.w);
			
				pos = p + PositionsBuffer[28];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[12].x), _Settings.w);
				pos = p + PositionsBuffer[29];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[13].x), _Settings.w);
				pos = p + PositionsBuffer[30];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[14].x), _Settings.w);
				pos = p + PositionsBuffer[31];				  
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[15].x), _Settings.w);
			
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

			for(float i = 0; i < count; i++)
			{
				float3 pos = p + PositionsBuffer[i];
				scene = opSmoothUnion(scene, sphereSDF(pos, ScaleBuffer[i].x), _Settings.w);
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
			//float3 c = float3(3, 3, 3);
			//float3 q = mod(p, c) - 0.5f * c;
			//float scene = dropSetOf16(q);
			return dropSetOf16(p);
			//return HavyScene(p);
		}


		float trace(float3 from, float3 direction, out float3 p)
		{
			float totalDistance = 0.0f;
			int steps;
			for (steps = 0; steps < _Settings.x; steps++)
			{
				p = from + totalDistance * direction;
				float distance = sceneSDF(p);
				totalDistance += distance;

				if (distance < _Settings.y)
				{
					break;
				}
			}
			return 1.0f - float(steps) / float(_Settings.x);
		}


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
            
			float3 xDir = float3(_Settings.y, 0.0f, 0.0f);
			float3 yDir = float3(0.0f, _Settings.y, 0.0f);
			float3 zDir = float3(0.0f, 0.0f, _Settings.y);
					
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
