// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Ocean Toolkit/Caustics Shader"
{
    Properties
    {
		[HideInInspector] _MainTex("Base", 2D) = "white" {}
		_Normal ("Normal", 2D) = "white" {}
        ot_Pattern0 ("Pattern 0", 2D) = "white" {}
		ot_RampDepth("Ramp Depth", float) = 1.0

		_FogDensity("Fog Density", Float) = 1.0
		_FogColor("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart("Fog Start", Float) = 0.0
		_FogEnd("Fog End", Float) = 1.0
		_WaterLevel("Water Level", Float) = 0.0

		_CausticsTextureScale("Caustics Scale", Float) = 5.0
		_CausticsStrength("Caustics Strength", Float) = 0.5
		_CausticsDistortionStrength("Caustics Distortion Strength", Float) = 0.075
		_CausticsDistortionScale("Caustics Distortion Scale", Float) = 5.0
		_CausticsFocalDepth("Caustics Focal Depth", Float) = 2.0
		_CausticsDepthOfField("Caustics Depth Of Field", Float) = 0.33
		_CausticsTextureAverage("Caustics Texture Average", Float) = 0.07
		_MaxDepth("Max Depth", Float) = 0.07
		_BeginPos("Begin Pos", Float) = 0.07
    }

    SubShader
    { 
		Tags { "RenderType" = "Opaque" }
        Pass
        {
			Tags { "LightMode" = "ForwardBase" }
            ZWrite On

            CGPROGRAM
			// Apparently need to add this declaration
			#pragma multi_compile_fwdbase	
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
			#include"UnityCG.cginc"
			#include"Lighting.cginc"
			#include "AutoLight.cginc"
            #include "CommonOceanToolkit.cginc"

            uniform sampler2D   _MainTex;
            uniform float4      _MainTex_TexelSize;

			uniform sampler2D   _Normal;
			uniform float4      _Normal_TexelSize;

            uniform sampler2D   ot_Pattern0;
            uniform float4      ot_Pattern0_ST;

            uniform float ot_RampDepth;

            uniform float3      ot_ViewSpaceUpDir;
            uniform float       ot_ZenithScalar;
            uniform float4x4    ot_InvViewProj;

			//UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
			float4x4 _FrustumCornersRay;
			half _FogDensity;
			fixed4 _FogColor;
			float _FogStart;
			float _FogEnd;


            struct VertexOutput
            {
                float4 position : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float4 worldFarPos : TEXCOORD1;
				float4 interpolatedRay : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				//SHADOW_COORDS(4)
            };

            VertexOutput vert(appdata_base input)
            {
                VertexOutput output;

                float4 projVertex = UnityObjectToClipPos(input.vertex);
                float4 screenPos = ComputeScreenPos(projVertex);

                output.position = projVertex;
                output.screenPos = screenPos;
                output.worldFarPos = mul(ot_InvViewProj, float4((screenPos.xy / screenPos.w) * 2.0 - 1.0, 1.0, 1.0));
				output.worldFarPos /= output.worldFarPos.w;
				output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;

				int index = 0;
				if (input.texcoord.x < 0.5 && input.texcoord.y < 0.5) {
					index = 0;
				}
				else if (input.texcoord.x > 0.5 && input.texcoord.y < 0.5) {
					index = 1;
				}
				else if (input.texcoord.x > 0.5 && input.texcoord.y > 0.5) {
					index = 2;
				}
				else {
					index = 3;
				}

#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					index = 3 - index;
#endif

				output.interpolatedRay = _FrustumCornersRay[index];
				//TRANSFER_SHADOW(output);

                return output;
            }

            float4 frag(VertexOutput input) : SV_Target
            {
                float2 uv = input.screenPos.xy / input.screenPos.w;

                float depth;
          /*      float3 normal;
                sampleDepthNormal(uv, depth, normal);*/
				depth = sampleDepth(uv);

                float3 pos = _WorldSpaceCameraPos.xyz + (input.worldFarPos.xyz - _WorldSpaceCameraPos.xyz) * depth;
                
				float3 caustics;

                #if defined(UNITY_UV_STARTS_AT_TOP)
                if (_MainTex_TexelSize.y < 0.0)
                {
                    uv.y = 1.0 - uv.y;
                }
                #endif

				// fog
				float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
				float3 worldPos = _WorldSpaceCameraPos + linearDepth * input.interpolatedRay.xyz;
				//return float4(linearDepth.xxxx);
				float dis = distance(worldPos, _WorldSpaceCameraPos);

				float fogDensity = (dis - _FogStart) * saturate(_WaterLevel - _WorldSpaceCameraPos.y) * saturate(_WaterLevel - worldPos.y) / _FogEnd;
				fogDensity = saturate(fogDensity * _FogDensity);
				// fog end

				// new Caustics
				half3 view = normalize(_WorldSpaceCameraPos - pos);
				float3 lightDir = WorldSpaceLightDir(pos);
				ApplyCaustics(view, lightDir, linearDepth, _Normal, ot_Pattern0, caustics);
				//new Caustics end


				//float4 shadowCoord = mul(unity_WorldToShadow[0], input.worldPos);

				//float shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, shadowCoord.xyz / shadowCoord.w);
				//return float4(shadow.xxxx);

				caustics = lerp(caustics, float3(0, 0, 0), fogDensity);

                float4 finalColor = tex2D(_MainTex, uv);
				finalColor = float4(finalColor.xyz + caustics, finalColor.w);
				finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
				return finalColor;
            }
            ENDCG
        }
    }
}