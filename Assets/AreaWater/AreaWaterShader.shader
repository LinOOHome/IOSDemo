Shader "Ocean Toolkit/AreaWaterShader"
{
	Properties
	{
		_NormalMap0("Normal Map 0", 2D) = "blue" {}
		_NormalMap1("Normal Map 1", 2D) = "blue" {}
		_FoamMap("Foam Map", 2D) = "white" {}

		_WaterLevel("Water Level", float) = 5
		_WindAngle("Wind Angle", float) = 5
		_WaveSpeeds("Wave Speeds", Vector) = (1.5, 3, 6, 2)
		_WaveAngles("Wave Angles", Vector) = (0.0, 17, 21, 51)
		_WaveScales("Wave Scales", Vector) = (0.3, 0.5, 0.3, 0.2)
		_WaveLengths("Wave Lengths", Vector) = (8.0, 30.0, 20.0, 10.0)
		_WaveExponents("Wave Exponents", Vector) = (1.3, 2.0, 1.8, 2.6)
		_WaveOffsets("Wave Offsets", Vector) = (3.0, 20.0, 50.0, 1.0)
		_WaveDirection01("Wave Direction01", Vector) = (3.0, 20.0, 50.0, 1.0)
		_WaveDirection23("Wave Direction23", Vector) = (3.0, 20.0, 50.0, 1.0)
		_WaveConstants("Wave Constants", Vector) = (3.0, 20.0, 50.0, 1.0)
		_WaveDerivativeConstants("Wave Derivative Constants", Vector) = (3.0, 20.0, 50.0, 1.0)

		_AbsorptionCoeffs("Absorption Coeffs", Vector) = (3.0, 20.0, 50.0, 1.0)
		_DetailFalloffStart("Detail Falloff Start", float) = 60.0
		_DetailFalloffDistance("Detail Falloff Distance", float) = 40.0
		_DetailFalloffNormalGoal("Detail Falloff Normal Goal", float) = 0.2
		_AlphaFalloff("Alpha Falloff", float) = 1.0
		_FoamFalloff("Foam Falloff", float) = 2.0
		_FoamStrength("Foam Strength", float) = 1.2
		_FoamAmbient("Foam Ambient", float) = 0.3
		_ReflStrength("Reflection Strength", float) = 0.9
		_RefrStrength("Refraction Strength", float) = 1.0
		_RefrColor("Refraction Color", Color) = (1.0, 0.0, 0.0, 1.0)
		_RefrNormalOffset("Refraction Normal Offset", float) = 0.05
		_RefrNormalOffsetRamp("Refraction Normal Offset Ramp", float) = 2.0
		_FresnelPow("Fresnel Pow", float) = 4.0
		_SunColor("Sun Color", Color) = (1.0, 0.95, 0.6)
		_DeepWaterColor("Deep Water Color", Color) = (0.045, 0.15, 0.3, 1.0)
		_DeepWaterAmbientBoost("Deep Water Ambient Boost", float) = 0.3
		_DeepWaterIntensityZenith("Deep Water Intensity Zenith", float) = 1.0
		_DeepWaterIntensityHorizon("Deep Water Intensity Horizon", float) = 0.4
		_DeepWaterIntensityDark("Deep Water Intensity Dark", float) = 0.1

		_FogColor("Fog Color", Color) = (0.045, 0.15, 0.3, 1.0)
		_FogStart("Fog Start", Float) = 0.0
		_FogEnd("Fog End", Float) = 20.0
		_FogDensity("Fog Density", Float) = 0.25
		_SpecularRoughness("SpecularRoughness", Float) = 0.0002
		_SpecularIntensity("SpecularIntensity", Float) = 0.02
	}
		SubShader
		{
			Tags
				{
					"RenderType" = "Transparent"
					"Queue" = "Transparent+100"
					"ForceNoShadowCasting" = "True"
					"IgnoreProjector" = "True"
				}

				GrabPass { "_Refraction" }

				Pass
				{
			//ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma shader_feature _REFL_OFF _REFL_SKY_ONLY _REFL_SSR
			//#pragma shader_feature _UNDER_SIDE
			#pragma shader_feature _REFR_OFF _REFR_COLOR _REFR_NORMAL_OFFSET
			//#include "CommonOceanToolkit.cginc"
			#include "UnityCG.cginc"
			#include "UnityGlobalIllumination.cginc"
			
			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 screenPos : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				UNITY_FOG_COORDS(3)
			};
		
		uniform sampler2D _CameraDepthTexture;

		// Currently set by material
		uniform sampler2D   _Refraction;
		uniform float4		_Refraction_TexelSize;

		uniform sampler2D _NormalMap0;
		uniform sampler2D _NormalMap1;
		uniform sampler2D _FoamMap;

		uniform float4 _NormalMap0_ST;
		uniform float4 _NormalMap1_ST;
		uniform float4 _FoamMap_ST;

		uniform float4  _AbsorptionCoeffs;
		uniform float   _DetailFalloffStart;
		uniform float   _DetailFalloffDistance;
		uniform float   _DetailFalloffNormalGoal;
		uniform float   _AlphaFalloff;
		uniform float   _FoamFalloff;
		uniform float   _FoamStrength;
		uniform float   _FoamAmbient;

		uniform float   _ReflStrength;
		uniform float   _RefrStrength;
		uniform float4  _RefrColor;
		uniform float   _RefrNormalOffset;
		uniform float   _RefrNormalOffsetRamp;
		uniform float   _FresnelPow;
		uniform float3  _DeepWaterColor;
		uniform float   _DeepWaterAmbientBoost;
		uniform float   _DeepWaterIntensityZenith;
		uniform float   _DeepWaterIntensityHorizon;
		uniform float   _DeepWaterIntensityDark;

		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;

		uniform float _WaterLevel;
		uniform float _WindAngle;
		uniform float4 _WaveSpeeds;
		uniform float4 _WaveAngles;
		uniform float4 _WaveScales;
		uniform float4 _WaveLengths;
		uniform float4 _WaveExponents;
		uniform float4 _WaveOffsets;
		uniform float2 _WaveOffsets01;
		uniform float2 _WaveOffsets23;
		uniform float4 _WaveDirection01;
		uniform float4 _WaveDirection23;
		uniform float4 _WaveConstants;
		uniform float4 _WaveDerivativeConstants;

		uniform float _SpecularRoughness;
		uniform float _SpecularIntensity;

#if !defined (M_PI)
#define M_PI 3.141592657
#endif

#if !defined (M_SQRT_PI)
#define M_SQRT_PI 1.7724538
#endif

		void UpdateParams()
		{
			//scaleSum = VH.Sum(waveScales);

			// Update wave function animation
			float4 wAngle = (float4(1,1,1,1) * _WindAngle + _WaveAngles);
			_WaveDirection01 = float4(cos(wAngle.x), sin(wAngle.x), cos(wAngle.y), sin(wAngle.y));
			_WaveDirection23 = float4(cos(wAngle.z), sin(wAngle.z), cos(wAngle.w), sin(wAngle.w));
			_WaveOffsets += _WaveSpeeds * _Time.y;
			_WaveConstants = float4(1, 1, 1, 1) * (2.0f * M_PI)/ _WaveLengths;
			_WaveDerivativeConstants = 0.5f * mul(mul(_WaveScales, _WaveConstants), _WaveExponents);

			// Update texture animations
			float nAngle0 = (_WindAngle + 30/*normalMapAngle0*/);
			float nAngle1 = (_WindAngle + 30/*normalMapAngle1*/);
			_WaveOffsets01 += float2(cos(nAngle0), sin(nAngle0)) * 30/*normalMapAngle0*/ * _Time.y;
			_WaveOffsets23 += float2(cos(nAngle1), sin(nAngle1)) * 30/*normalMapAngle1*/ * _Time.y;

	/*		float fAngle = (_WindAngle + foamMapAngle);
			foamMapOffset += float2(cos(fAngle), sin(fAngle)) * foamMapSpeed * _Time.y;*/
		}

		void waveHeight(float3 pos, out float height, out float3 normal)
		{
			UpdateParams();
			float4 locations = float4(dot(_WaveDirection01.xy, pos.xz), dot(_WaveDirection01.zw, pos.xz), dot(_WaveDirection23.xy, pos.xz), dot(_WaveDirection23.zw, pos.xz));
			float4 axesX = float4(_WaveDirection01.x, _WaveDirection01.z, _WaveDirection23.x, _WaveDirection23.z);
			float4 axesY = float4(_WaveDirection01.y, _WaveDirection01.w, _WaveDirection23.y, _WaveDirection23.w);

			float4 sine = sin((locations + _WaveOffsets) * _WaveConstants) * 0.5 + 0.5;
			// sine = 0.0; // To disable waves
			float4 cosine = cos((locations + _WaveOffsets) * _WaveConstants);

			float sum = dot(_WaveScales, pow(sine, _WaveExponents));
			float tangentSum = dot(axesX * _WaveDerivativeConstants, pow(sine, _WaveExponents - 0.99) * cosine);
			float bitangentSum = dot(axesY * _WaveDerivativeConstants, pow(sine, _WaveExponents - 0.99) * cosine);

			float3 tangent = float3(1.0, tangentSum, 0.0);
			float3 bitangent = float3(0.0, bitangentSum, 1.0);

			height = _WaterLevel + sum;
			normal = normalize(cross(bitangent, tangent));
		}


		v2f vert(appdata_full v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			float height;
			float3 worldNormal = v.normal;// float3(0, 0, 1);
			float3 worldVertex = mul(unity_ObjectToWorld,v.vertex);
			waveHeight(worldVertex, height, worldNormal);
			worldVertex.y = height;

			float4 projVertex = mul(UNITY_MATRIX_VP, float4(worldVertex, 1.0));
			o.pos = projVertex;
			o.screenPos = ComputeScreenPos(projVertex);
			o.worldPos = worldVertex;
			o.worldNormal = worldNormal;
			return o;
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

		inline float3 calcReflDir(float3 viewDir, float3 normal)
		{
			// We should re-normalize reflDir after the saturation, but
			// let's optimize for the common case and not do it
			float3 reflDir = reflect(viewDir, normal);
			reflDir.y = saturate(reflDir.y);
			return reflDir;
		}

		inline float3 sampleSky(float3 dir)
		{
			UnityGIInput data;
			UNITY_INITIALIZE_OUTPUT(UnityGIInput, data); //data.worldPos = float3(0.0, 0.0, 0.0)
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
				float depth = Linear01Depth(tex2Dlod(_CameraDepthTexture, float4(P, 0.0, 0.0))).r * _ProjectionParams.z; // multiply by far plane

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

		float4 frag(v2f i) : SV_Target
		{
			//return float4(0,1,1,1);
			float screenZ = i.screenPos.w;

			// Get rough normal from wave function
			float3 normal = i.worldNormal;

			// Get fine normal from normal maps
			float2 normalUv0 = TRANSFORM_TEX(i.worldPos.xz, _NormalMap0);
			float3 fineNormal0 = UnpackNormal(tex2D(_NormalMap0, normalUv0)).xzy;
			float2 normalUv1 = TRANSFORM_TEX(i.worldPos.xz, _NormalMap1);
			float3 fineNormal1 = UnpackNormal(tex2D(_NormalMap1, normalUv1)).xzy;
			float3 fineNormal = fineNormal0 + fineNormal1;
			// DEBUG: return float4(fineNormal.xzy * 0.5 + 0.5, 1.0);

			// Fade normal towards the horizon
			float detailFalloff = saturate((screenZ - _DetailFalloffStart) / _DetailFalloffDistance);
			fineNormal = normalize(lerp(fineNormal, float3(0.0, 2.0, 0.0), saturate(detailFalloff - _DetailFalloffNormalGoal)));
			normal = normalize(lerp(normal, float3(0.0, 1.0, 0.0), detailFalloff));

			// Transform fine normal to world space
			float3 tangent = cross(normal, float3(0.0, 0.0, 1.0));
			float3 bitangent = cross(tangent, normal);
			normal = tangent * fineNormal.x + normal * fineNormal.y + bitangent * fineNormal.z;
//#if defined(_UNDER_SIDE)
//			normal.y *= -1;
//#endif
			float3 viewDir = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);
			float3 reflDir = calcReflDir(viewDir, normal);

			// ---
			// Sun
			// ---
			float3 sun;
			float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
			// ----------
			// Reflection
			// ----------
			float3 refl = float3(0.0, 1.0, 1.0);

			#if defined(_REFL_SKY_ONLY)
				#if UNITY_SPECCUBE_BOX_PROJECTION
					refl = sampleSky(reflDir);
				#else
					refl = float3(0.8, 0.9, 1);
				#endif              
			#endif

			#if defined(_REFL_SSR)
				float2 hitCoord;
				float hitZ;

				if (raytrace2d(i.worldPos, reflDir, 50.0, UNITY_MATRIX_V, UNITY_MATRIX_P, 64.0, 4.0, 1.0, hitCoord, hitZ))
				{
					#if defined(UNITY_UV_STARTS_AT_TOP)
					if (_Refraction_TexelSize.y < 0.0 && _ProjectionParams.x >= 0.0)
					{
						hitCoord.y = 1.0 - hitCoord.y;
					}
					#endif

					refl = tex2Dlod(_Refraction, float4(hitCoord, 0.0, 0.0)).xyz;
					sun *= 0.0;
				}
				else
				{
					#if UNITY_SPECCUBE_BOX_PROJECTION
						refl = sampleSky(reflDir);
					#else
						refl = float3(0.8, 0.9, 1);
					#endif      
				}
			#endif

				// ----------
				// Refraction
				// ----------
				float3 refr = float3(0.0, 1.0, 1.0);

				float2 uv = i.screenPos.xy / i.screenPos.w;
				float depthBelowSurface = Linear01Depth(tex2D(_CameraDepthTexture, uv)).r * _ProjectionParams.z - screenZ;

				float refrDepthBelowSurface = depthBelowSurface;

				#if defined(_REFR_COLOR)
				refr = _RefrColor.xyz;
				#endif

				//#if defined(_REFR_NORMAL_OFFSET)
				// Sample refraction first using offset proportional to the center reference depth. This makes the
				// surface transition "inside" objects smooth.
				/*float2 refrUv = uv + normal.xz * _RefrNormalOffset * saturate(depthBelowSurface / _RefrNormalOffsetRamp);
				refrDepthBelowSurface = sampleDepth(refrUv) * _ProjectionParams.z - screenZ;*/

				// Now, sample refraction using offset proportional to the refracted depth. This makes the
				// surface transition "outside" objects smooth.
				float2 refrUv = uv + normal.xz * _RefrNormalOffset * saturate(refrDepthBelowSurface / _RefrNormalOffsetRamp);
				refrDepthBelowSurface = Linear01Depth(tex2D(_CameraDepthTexture, refrUv)).r * _ProjectionParams.z - screenZ;


				// This procedure removes artifacts close to the surface, the downside is that we
				// need to sample the depth twice for refraction.

				// Is the refracted sample on geometry above the surface?
				if (refrDepthBelowSurface < 0.0)
				{
					refrUv = uv;
					refrDepthBelowSurface = depthBelowSurface;
				}

				#if defined(UNITY_UV_STARTS_AT_TOP)
				if (_Refraction_TexelSize.y < 0.0 && _ProjectionParams.x >= 0.0)
				{
					refrUv.y = 1.0 - refrUv.y;
				}
				#endif

				refr = tex2D(_Refraction, refrUv).xyz;
				//#endif

				float dwScalar = 0;
				/*if (lightDir.y >= 0.0f) ///???没搞懂这个为什么要区分计算
				{*/
					dwScalar = lerp(_DeepWaterIntensityHorizon, _DeepWaterIntensityZenith, lightDir.y);
				/*}
				else
				{
					dwScalar = lerp(_DeepWaterIntensityHorizon, _DeepWaterIntensityDark, -lightDir.y);
				}*/

				_DeepWaterColor *= dwScalar;

				// Absorb light relative to depth
				float viewDotNormal = saturate(dot(-viewDir, normal));
				float3 deepWaterColor = _DeepWaterColor * (1.0 + pow(viewDotNormal, 2.0) * _DeepWaterAmbientBoost);

				refr = lerp(refr, deepWaterColor, saturate(refrDepthBelowSurface.xxx / _AbsorptionCoeffs.xyz));

				// ----
				// Foam
				// ----
				// Depth-based
				// Wave-tops, pre-computed depth in the future?
				float foamShade = saturate(_FoamAmbient + dot(normal, lightDir));
				float foamMask = 1.0 - pow(saturate(refrDepthBelowSurface / _FoamFalloff), 4.0);
				float2 foamUv = TRANSFORM_TEX(i.worldPos.xz, _FoamMap);
				float foam = foamMask * _FoamStrength * foamShade * tex2D(_FoamMap, foamUv).w;

				// ------------------
				// Combine everything
				// ------------------
				float fresnel = 0.0;

		#if defined(_REFL_OFF)
				fresnel = 0.0;
		#else
			#if defined(_REFR_OFF)
				fresnel = 1.0;
			#else
				fresnel = pow(1.0 - viewDotNormal, _FresnelPow)*(saturate(_WorldSpaceCameraPos.y - i.worldPos.y) + 0.025);
			#endif
		#endif
	
					sun = ReflectedSunRadianceNice(-viewDir, normal, lightDir, fresnel);

					float dis = distance(i.worldPos, _WorldSpaceCameraPos);

					float dist = (dis - _FogStart)*saturate(i.worldPos.y - _WorldSpaceCameraPos.y) / _FogEnd;
					float fogDensity = saturate(dist * _FogDensity);

					float3 color = (1.0 - foam) * (fresnel * _ReflStrength * refl + (1.0 - fresnel) * _RefrStrength * refr) + foam.xxx;

					color.rgb = lerp(color.rgb, _FogColor.rgb, fogDensity);

					float alpha = saturate(depthBelowSurface / _AlphaFalloff);
	//#if defined(_UNDER_SIDE)

	//				half3 inscatterScale;
	//				inscatterScale.x = saturate(dist * _FogDensity);
	//				inscatterScale.y = saturate(1.0 - exp(-dist * _FogDensity));
	//				inscatterScale.z = saturate(1.0 - exp(-dist * dist * _FogDensity));

	//				//Apply mask to pick which methods result to use.
	//				//Better than conditional statement?
	//				half a = dot(inscatterScale, 1);

	//				color = lerp(color, _FogColor.rgb, a * _FogColor.a);

	//				alpha = 1;// lerp(1, fogDensity, fogDensity);
	//#endif
					return float4(color + sun * _LightColor0.rgb, alpha);
				}
				ENDCG
			}
		}
}
