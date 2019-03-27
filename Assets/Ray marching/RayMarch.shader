Shader "Neitron/RayMarch"
{
	Properties
	{
		[Toogle]_Grid("Grid", Float) = 0
		_Settings("Max Ray Steps, MinDistance, Radius, CamPosZ", Vector) = (10.0, 1.0, 1.0, 0.0)
		_Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_Metallic ("Metalic", Float) = 0.2
		_Smoothness("Smoothness", Float) = 0.2
		
		
		//_Color2("Color 2", Color) = (1.0, 1.0, 1.0, 1.0)
		//_Color3("Color 3", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader
	{
		Tags 
		{ 
			"Queue" = "Transparent" 
			"RenderType" = "Transparent"
		}
		LOD 100
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		Pass
		{
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			
			#pragma target 3.0

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"
			#include "../Cg/Helpers.cginc"
			#include "RayMarch.cginc"

			ENDCG
		}
	}
}

