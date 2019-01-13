#ifndef COMMON_OCEAN_TOOLKIT
#define COMMON_OCEAN_TOOLKIT
#include "UnityCG.cginc"
#include "UnityGlobalIllumination.cginc"

//uniform sampler2D _CameraDepthNormalsTexture;
uniform sampler2D _CameraDepthTexture;

uniform float ot_OceanPosition;

uniform float4 ot_WaveScales;
uniform float4 ot_WaveLengths;
uniform float4 ot_WaveExponents;
uniform float4 ot_WaveOffsets;
uniform float4 ot_WaveDirection01;
uniform float4 ot_WaveDirection23;
uniform float4 ot_WaveConstants;
uniform float4 ot_WaveDerivativeConstants;

uniform float3 _OceanCenterPosWorld;
uniform float4 _LD_Params_1;
uniform float3 _LD_Pos_Scale_1;
uniform sampler2D _LD_Sampler_AnimatedWaves_1; \
uniform sampler2D _LD_Sampler_SeaFloorDepth_1; \
uniform sampler2D _LD_Sampler_Foam_1; \
uniform sampler2D _LD_Sampler_Flow_1; \
uniform sampler2D _LD_Sampler_DynamicWaves_1; \
uniform sampler2D _LD_Sampler_Shadow_1; \

uniform float _CrestTime;

uniform sampler2D _CausticsTexture;
uniform half _CausticsTextureScale;
uniform half _CausticsTextureAverage;
uniform half _CausticsStrength;
uniform half _CausticsFocalDepth;
uniform half _CausticsDepthOfField;
uniform half _CausticsDistortionScale;
uniform half _CausticsDistortionStrength;
uniform float _SpecularRoughness;
uniform float _SpecularIntensity;
uniform	float _WaterLevel;
uniform	float _MaxDepth;
uniform	float _BeginPos;

#if !defined (M_PI)
#define M_PI 3.141592657
#endif

#if !defined (M_SQRT_PI)
#define M_SQRT_PI 1.7724538
#endif

inline void waveHeight(float3 pos, out float height, out float3 normal)
{
	float4 locations = float4(dot(ot_WaveDirection01.xy, pos.xz), dot(ot_WaveDirection01.zw, pos.xz), dot(ot_WaveDirection23.xy, pos.xz), dot(ot_WaveDirection23.zw, pos.xz));
	float4 axesX = float4(ot_WaveDirection01.x, ot_WaveDirection01.z, ot_WaveDirection23.x, ot_WaveDirection23.z);
	float4 axesY = float4(ot_WaveDirection01.y, ot_WaveDirection01.w, ot_WaveDirection23.y, ot_WaveDirection23.w);

	float4 sine = sin((locations + ot_WaveOffsets) * ot_WaveConstants) * 0.5 + 0.5;
	// sine = 0.0; // To disable waves
	float4 cosine = cos((locations + ot_WaveOffsets) * ot_WaveConstants);

	float sum = dot(ot_WaveScales, pow(sine, ot_WaveExponents));
	float tangentSum = dot(axesX * ot_WaveDerivativeConstants, pow(sine, ot_WaveExponents - 0.99) * cosine);
	float bitangentSum = dot(axesY * ot_WaveDerivativeConstants, pow(sine, ot_WaveExponents - 0.99) * cosine);

	float3 tangent = float3(1.0, tangentSum, 0.0);
	float3 bitangent = float3(0.0, bitangentSum, 1.0);

	height = ot_OceanPosition + sum;
	normal = normalize(cross(bitangent, tangent));
}

float3 WorldSpaceLightDir(float3 worldPos)
{
	float3 lightDir = _WorldSpaceLightPos0.xyz;
	if (_WorldSpaceLightPos0.w > 0.)
	{
		// non-directional light - this is a position, not a direction
		lightDir = normalize(lightDir - worldPos.xyz);
	}
	return lightDir;
}

float2 LD_WorldToUV(in float2 i_samplePos, in float2 i_centerPos, in float i_res, in float i_texelSize)
{
	return (i_samplePos - i_centerPos) / (i_texelSize * i_res) + 0.5;
}
float2 LD_1_WorldToUV(in float2 i_samplePos) { return LD_WorldToUV(i_samplePos, _LD_Pos_Scale_1.xy, _LD_Params_1.y, _LD_Params_1.x); }

// Sampling functions
void SampleDisplacements(in sampler2D i_dispSampler, in float2 i_uv, in float i_wt, inout float3 io_worldPos)
{
	const half3 disp = tex2Dlod(i_dispSampler, float4(i_uv, 0., 0.)).xyz;
	io_worldPos += i_wt * disp;
}

//#if _CAUSTICS_ON
inline void ApplyCaustics(in half3 i_view, in half3 i_lightDir, in float i_sceneZ, in sampler2D i_normals, in sampler2D _CausticsTex, inout float3 io_sceneColour)
{
	_OceanCenterPosWorld.y = _WaterLevel;
	_CrestTime = _Time.y;
	// could sample from the screen space shadow texture to attenuate this..
	// underwater caustics - dedicated to P
	float3 camForward = mul((float3x3)unity_CameraToWorld, float3(0., 0., 1.));
	float3 scenePos = _WorldSpaceCameraPos - i_view * i_sceneZ / dot(camForward, -i_view);
	const float2 scenePosUV = LD_1_WorldToUV(scenePos.xz);
	half3 disp = 0.;
	// this gives height at displaced position, not exactly at query position.. but it helps. i cant pass this from vert shader
	// because i dont know it at scene pos.
	SampleDisplacements(_LD_Sampler_AnimatedWaves_1, scenePosUV, 1.0, disp);
	half waterHeight = _OceanCenterPosWorld.y + disp.y;
	half sceneDepth = waterHeight - scenePos.y;
	float depthFallOff;
	depthFallOff = lerp(0, 1, (_MaxDepth - sceneDepth) / _MaxDepth);
	_WaterLevel = _WaterLevel + _BeginPos;
	if (scenePos.y > _WaterLevel)
	{
		depthFallOff = 0;
	}
	else
	{
		if (scenePos.y > _WaterLevel - 1 && scenePos.y < _WaterLevel)
		{
			//lerp(a, b, c) = a + (b - a) * c;
			depthFallOff = lerp(0, depthFallOff, _WaterLevel - scenePos.y);
		}
	}

	half bias = 1;// abs(sceneDepth - _CausticsFocalDepth) / _CausticsDepthOfField;
	// project along light dir, but multiply by a fudge factor reduce the angle bit - compensates for fact that in real life
	// caustics come from many directions and don't exhibit such a strong directonality
	float2 surfacePosXZ = scenePos.xz + i_lightDir.xz * sceneDepth / (4.*i_lightDir.y);
	half2 causticN = _CausticsDistortionStrength * UnpackNormal(tex2D(i_normals, surfacePosXZ / _CausticsDistortionScale)).xy;
	half4 cuv1 = half4((surfacePosXZ / _CausticsTextureScale + 1.3 *causticN + half2(0.044*_CrestTime + 17.16, -0.169*_CrestTime)), 0., bias);
	half4 cuv2 = half4((1.37*surfacePosXZ / _CausticsTextureScale + 1.77*causticN + half2(0.248*_CrestTime, 0.117*_CrestTime)), 0., bias);

	half causticsStrength = _CausticsStrength;

	io_sceneColour =/* 1.0 +*/ causticsStrength *
		(0.5*tex2Dlod(_CausticsTex, cuv1).x + 0.5*tex2Dlod(_CausticsTex, cuv2).x - _CausticsTextureAverage);
	//io_sceneColour = tex2Dlod(_CausticsTex, cuv1);
	io_sceneColour *= saturate(depthFallOff);
}
//#endif // _CAUSTICS_ON

// From UnityCG.cginc: "Linear01Depth - Z buffer to linear 0..1 depth (0 at eye, 1 at far plane)"
// "return Linear01Depth(tex2D(_CameraDepthTexture, uv).x);"

//inline void sampleDepthNormal(float2 uv, out float depth, out float3 viewNormal)
//{
//	DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv), depth, viewNormal);
//}

inline float sampleDepth(float2 uv)
{
	float depth;
	//float3 viewNormal;
	//DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, uv), depth, viewNormal);
	depth = Linear01Depth(tex2D(_CameraDepthTexture, uv)).r;
	return depth;
}

inline float sampleDepthLOD(float4 uv)
{
	float depth;
	//   float3 viewNormal;
	   //DecodeDepthNormal(tex2Dlod(_CameraDepthNormalsTexture, uv), depth, viewNormal);
	   //depth = tex2Dlod(_CameraDepthNormalsTexture, uv).r;
	depth = Linear01Depth(tex2Dlod(_CameraDepthTexture, uv)).r;
	return depth;
}

inline float3 sampleSky(float3 dir)
{
	UnityGIInput data;
	UNITY_INITIALIZE_OUTPUT(UnityGIInput, data); // data.worldPos = float3(0.0, 0.0, 0.0)
#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
	data.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
#endif

#if UNITY_SPECCUBE_BOX_PROJECTION
	data.boxMax[0] = unity_SpecCube0_BoxMax;
	data.probePosition[0] = unity_SpecCube0_ProbePosition;
	data.probeHDR[0] = unity_SpecCube0_HDR;
	data.boxMin[1] = unity_SpecCube1_BoxMin;
	data.boxMax[1] = unity_SpecCube1_BoxMax;
	data.probePosition[1] = unity_SpecCube1_ProbePosition;
	data.probeHDR[1] = unity_SpecCube1_HDR;
#endif

	Unity_GlossyEnvironmentData g;
	UNITY_INITIALIZE_OUTPUT(Unity_GlossyEnvironmentData, g); // g.roughness = 0.0
	g.reflUVW = dir;

	return UnityGI_IndirectSpecular(data, 1.0, float3(0.0, 0.0, 0.0), g);
	//return Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, dir, -1.0);
}

half Lambda(half cosTheta, half sigma)
{
	half v = cosTheta / sqrt((1.0 - cosTheta * cosTheta) * (2.0 * sigma));
	return (exp(-v * v)) / (2.0 * v * M_SQRT_PI);
}

half3 ReflectedSunRadianceNice(half3 V, half3 N, half3 L, fixed fresnel)
{

	half3 Ty = half3(0.0, N.z, -N.y);
	half3 Tx = cross(Ty, N);

	half3 H = normalize(L + V);
	half dhn = dot(H, N);
	half idhn = 1.0 / dhn;
	half zetax = dot(H, Tx) * idhn;
	half zetay = dot(H, Ty) * idhn;

	half p = exp(-0.5 * (zetax * zetax / _SpecularRoughness + zetay * zetay / _SpecularRoughness)) / (2.0 * M_PI * _SpecularRoughness);

	half zL = dot(L, N); // cos of source zenith angle
	half zV = dot(V, N); // cos of receiver zenith angle
	half zH = dhn; // cos of facet normal zenith angle
	half zH2 = zH * zH;

	half tanV = atan2(dot(V, Ty), dot(V, Tx));
	half cosV2 = 1.0 / (1.0 + tanV * tanV);
	half sigmaV2 = _SpecularRoughness * cosV2 + _SpecularRoughness * (1.0 - cosV2);

	half tanL = atan2(dot(L, Ty), dot(L, Tx));
	half cosL2 = 1.0 / (1.0 + tanL * tanL);
	half sigmaL2 = _SpecularRoughness * cosL2 + _SpecularRoughness * (1.0 - cosL2);

	zL = max(zL, 0.01);
	zV = max(zV, 0.01);

	return (L.y < 0) ? 0.0 : _SpecularIntensity * p / ((1.0 + Lambda(zL, sigmaL2) + Lambda(zV, sigmaV2)) * zV * zH2 * zH2 * 4.0);

}

inline float distanceSquared(float2 a, float2 b)
{
	float2 delta = b - a;

	return dot(delta, delta);
}

// Heavily inspired by "Efficient GPU Screen-Space Ray Tracing" by Morgan McGuire and Michael Mara
bool raytrace2d(const float3 worldStart, const float3 worldDir, float worldDistance,
	const float4x4 view, float4x4 proj,
	const float samples, const float stride, const float zThickness,
	out float2 hitCoord, out float hitZ)
{
	// Set output
	hitCoord = float2(-1.0, -1.0);
	hitZ = -1.0;

	// Move to view-space
	float3 view0 = mul(view, float4(worldStart, 1.0)).xyz;
	float3 viewDir = normalize(mul(view, float4(worldDir, 0.0)).xyz);

	// Clip ray to near plane
	float viewNearPlane = -_ProjectionParams.y;
	float rayLength = view0.z + viewDir.z * worldDistance > viewNearPlane ? (viewNearPlane - view0.z) / viewDir.z : worldDistance;

	float3 view1 = view0 + viewDir * rayLength;

	// Move to NDC-space
	float4 ray0 = mul(proj, float4(view0, 1.0));
	float4 ray1 = mul(proj, float4(view1, 1.0));

	float k0 = 1.0 / ray0.w;
	float k1 = 1.0 / ray1.w;

	float3 Qk0 = view0 * k0;
	float3 Qk1 = view1 * k1;

	// Screen points
	float2 screen0 = ComputeScreenPos(ray0 * k0).xy;
	float2 screen1 = ComputeScreenPos(ray1 * k1).xy;

	if (distanceSquared(screen0, screen1) <= 0.001)
	{
		screen1 += float2(1.0, 1.0) / _ScreenParams.xy;
	}

	// How far do we need to step along the ray in order to move 1 pixel along the lowest slope?
	float2 absDelta = abs(screen1 - screen0);

	float stepOnePixel = absDelta.x > absDelta.y ? 1.0 / (absDelta.x * _ScreenParams.x) : 1.0 / (absDelta.y * _ScreenParams.y);
	float step = stepOnePixel * stride;

	// Calculate deltas
	float kStep = (k1 - k0) * step;
	float3 QkStep = (Qk1 - Qk0) * step;
	float2 PStep = (screen1 - screen0) * step;

	// When talking about Z from now on, positive values go into the screen
	float prevMaxRayZ = -view0.z; // (-view0.z equals ray0.w in perspective transform)

	float scalar = 0.0;
	float k = k0;
	float3 Qk = Qk0;
	float2 P = screen0;

	// Step along the ray and make sure that we don't use too many samples or walk too far
	for (float i = 0.0; i < samples && scalar <= 1.0; i++)
	{
		// Calculate Z at next half-pixel
		float3 Q = (Qk + QkStep * 0.5) / (k + kStep * 0.5);

		float minRayZ = prevMaxRayZ;
		float maxRayZ = -Q.z;
		prevMaxRayZ = maxRayZ;

		// Handle rays travelling towards the camera
		if (maxRayZ < minRayZ)
		{
			float t = minRayZ;
			minRayZ = maxRayZ;
			maxRayZ = t;
		}

		// Get Z-buffer depth at this pixel
		float depth = sampleDepthLOD(float4(P, 0.0, 0.0)) * _ProjectionParams.z; // multiply by far plane

		// Previous implementation just to be safe, the following worked well:
		// depth = LinearEyeDepth(tex2Dlod(_CameraDepthTexture, float4(P, 0.0, 0.0)).x);

		float minSampleZ = depth;
		float maxSampleZ = minSampleZ + zThickness;

		// Do we intersect geometry at this pixel?
		if (maxRayZ > minSampleZ && minRayZ < maxSampleZ)
		{
			hitCoord = P;
			hitZ = minSampleZ;
			break;
		}

		// Snap to next pixel
		scalar += step;
		k += kStep;
		Qk += QkStep;
		P += PStep;
	}

	return hitZ >= 0.0;
}

#endif