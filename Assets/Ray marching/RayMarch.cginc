
struct appdata
{
    float4 vertex : POSITION;
};


struct v2f
{
    float4 vertex : SV_POSITION;
    float4 objPos : TEXCOORD0;
    float3 worldDir : TEXCOORD1;
};


v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.objPos = v.vertex;

    /// Returns world space direction 
    /// (not normalized) from given object 
    /// space vertex position towards the camera.
    o.worldDir = WorldSpaceViewDir(v.vertex);

    return o;
}


float4 _Settings;

float MaxRaySteps;
float MinDistance;
float RADIUS;
float CAM_POS_Z;
fixed4 _Color;



float sphereSDF(float3 p, float r)
{
    return length(p) - r;
}


float roundBoxSDF( float3 p, float3 b, float r )
{
    float3 d = abs(p) - b;
    return length(max(d, 0.0)) - r
            + min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf 
}


float torusSDF( float3 p, float2 t )
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}


float opSmoothUnion( float d1, float d2, float k )
{
	float h = clamp( 0.5f + 0.5f * (d2 - d1) / k, 0.0f, 1.0f );
	return lerp( d2, d1, h ) - k * h * (1.0f - h);
}


float opSmoothSubtraction( float d1, float d2, float k ) 
{
    float h = clamp( 0.5f - 0.5f * (d2 + d1) / k, 0.0f, 1.0f );
    return lerp( d2, -d1, h ) + k * h * (1.0f - h); 
}


float opSmoothIntersection( float d1, float d2, float k ) 
{
    float h = clamp( 0.5f - 0.5f * (d2 - d1) / k, 0.0f, 1.0f );
    return lerp( d2, d1, h ) + k * h * (1.0f - h); 
}


float opDisplace( float q, float3 p, float4 d )
{
    float d1 = q;
    float d2 = sin(d.x * p.x) * sin(d.y * p.y) * sin(d.z * p.z) * d.w;
    return d1 + d2;
}


float3 opTwist( float3 p, float2 t )
{
    float c = cos(t.x * p.y);
    float s = sin(t.y * p.y);
    float2x2 m = float2x2(c, -s, s, c);
    float3 q = float3(mul(m, p.xz), p.y);
    return q;
}


float3 opCheapBend( float3 p )
{
    float c = cos(1.0 * p.y);
    float s = sin(1.0 * p.y);
    float2x2 m = float2x2(c, -s, s, c);
    float3 q = float3(mul(m, p.xy), p.z);
    return q;
}


float3 rotateX(float3 p, float a)
{
    return mul(float3x3(1,0,0, 0,cos(a),-sin(a), 0,sin(a),cos(a)), p);
}

/*
float sceneSDF(float3 p)
{
    // twisted torus
    // float scene = opSmoothUnion( roundBoxSDF( opTwist(p, sin(_Time.y) * 15.0f), _Settings.z * 0.5, 0.1), sphereSDF(p - float3(sin(_Time.y) * 0.6, sin(_Time.y), 0) * 0.6, _Settings.z * 0.5 ), _Settings.w);
    
    // twisted torus
    //float3 r = rotateX(p, DEG_TO_RAD(90));
    float3 t = opTwist(p, _SinTime.w * 15.0f);
    float tor = torusSDF( t, float2(_Settings.z * 0.6, _Settings.z * 0.3));
    float sph1 = sphereSDF( p - float3(_SinTime.w * _Settings.z, _CosTime.w * _Settings.z, 0), _Settings.z * 0.35 );
    float sph2 = sphereSDF( p - float3(-_SinTime.w * _Settings.z, _CosTime.w * _Settings.z, 0), _Settings.z * 0.35 );
    float scene = opSmoothUnion(tor, sph1, _Settings.w);
    scene = opSmoothUnion(scene, sph2, _Settings.w);
    
    return scene;
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

float _Smoothness;
float _Metallic;


fixed4 frag (v2f i) : SV_Target
{
    float3 p; // closest point
    float3 viewDir = normalize(i.worldDir);
    float res = trace(_WorldSpaceCameraPos, -viewDir, p);
    
    float3 xDir = float3(_Settings.y, 0.0f, 0.0f);
    float3 yDir = float3(0.0f, _Settings.y, 0.0f);
    float3 zDir = float3(0.0f, 0.0f, _Settings.y);

    float3 norm = normalize(float3(
        sceneSDF(p + xDir)-sceneSDF(p - xDir),
		sceneSDF(p + yDir)-sceneSDF(p - yDir),
		sceneSDF(p + zDir)-sceneSDF(p - zDir)));

    
    float3 lightDir = _WorldSpaceLightPos0.xyz;

    fixed3 finalColor = _Color.rgb * res;

	float3 lightColor = _LightColor0.rgb;
	float3 albedo = finalColor; //tex2D(_MainTex, i.uv).rgb * _Tint.rgb

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(
		albedo, _Metallic, specularTint, oneMinusReflectivity
	);
				
	UnityLight light;
	light.color = lightColor;
	light.dir = lightDir;
	light.ndotl = DotClamped(norm, lightDir);

	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

    indirectLight.diffuse += max(0, ShadeSH9(float4(norm, 1)));
    float3 reflectionDir = reflect(-viewDir, norm);
    
    Unity_GlossyEnvironmentData envData;
	envData.roughness = 1 - _Smoothness;
	envData.reflUVW = reflectionDir;
	indirectLight.specular = Unity_GlossyEnvironment(
		UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
	);

    // Full Light
    return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					norm, viewDir,
					light, indirectLight
				) * step( length(p), 100);

    
    // Just color
    return fixed4(finalColor, 1.0f);
}
*/