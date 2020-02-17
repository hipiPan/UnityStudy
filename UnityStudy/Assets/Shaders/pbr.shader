Shader "Custom/pbr"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
		
		Pass 
		{
			CGPROGRAM //todo
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _SphereLitCount;
            float4 _SphereLitPosList[4];
            float4 _SphereLitColList[4];
            float _SpotLitCount;
            float4 _SpotLitPosList[4];
            float4 _SpotLitColList[4];
            float4 _SpotLitDirList[4];

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 posWorld : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 eyeDir : TEXCOORD3;
            };

            v2f vert(appdata v) {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.eyeDir.xyz = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz).xyz;
                return o;
            }

            float smoothDistanceAtt(float squaredDistance , float invSqrAttRadius)
            { 
                float factor = squaredDistance * invSqrAttRadius;
                float smoothFactor = saturate(1.0f - factor * factor);
                return smoothFactor * smoothFactor;
            }

            float getDistanceAtt(float3 unormalizedLightVector , float invSqrAttRadius)
            { 
                float sqrDist = dot(unormalizedLightVector , unormalizedLightVector);
                float attenuation = 1.0 / (max(sqrDist , 0.01*0.01));
                attenuation *= smoothDistanceAtt(sqrDist , invSqrAttRadius); 
                return attenuation;
            }

            float getAngleAtt(float3 normalizedLightVector, float3 lightDir, float lightAngleScale , float lightAngleOffset)
            {
                float cd = dot(lightDir , normalizedLightVector); 
                float attenuation = saturate(cd * lightAngleScale + lightAngleOffset); 
                attenuation *= attenuation;
                return attenuation; 
            } 

            // calcDynamicLighting
            
            // calcMainLighting

            fixed4 frag(v2f i) : COLOR {
                fixed4 albedo = tex2D(_MainTex, i.uv);
                float3 N = normalize(i.normal);
                float3 Lo = float3(0.0, 0.0, 0.0);
                
                // calcDynamicLighting
                for(int n = 0; n < _SphereLitCount; n++)
                {
                    float3 unnormalizedLightVector = _SphereLitPosList[n].xyz - i.posWorld;
                    float3 L = normalize(unnormalizedLightVector);
                    float lightInvSqrAttRadius = 1.0 / (_SphereLitPosList[n].w * _SphereLitPosList[n].w);
                    float att = 1.0;
                    att *= getDistanceAtt(unnormalizedLightVector, lightInvSqrAttRadius);
                    Lo += (albedo / 3.1415926) * saturate(dot(N, L)) * att * _SphereLitColList[n].xyz * _SphereLitColList[n].w;
                }

                for(int n = 0; n < _SpotLitCount; n++)
                {
                    float3 unnormalizedLightVector = _SpotLitPosList[n].xyz - i.posWorld;
                    float3 L = normalize(unnormalizedLightVector);
                    float lightInvSqrAttRadius = 1.0 / (_SpotLitPosList[n].w * _SpotLitPosList[n].w);

                    float cosInner = max(dot(-_SpotLitDirList[n].xyz, L), 0.01);
                    float cosOuter = _SpotLitDirList[n].w;
                    float litAngleScale = 1.0 / max(0.001, cosInner - cosOuter);
                    float litAngleOffset = -cosOuter * litAngleScale;
                    float att = 1.0;
                    att *= getDistanceAtt(unnormalizedLightVector, lightInvSqrAttRadius);
                    att *= getAngleAtt(L, -_SpotLitDirList[n].xyz, litAngleScale, litAngleOffset);
                    Lo += (albedo / 3.1415926) * saturate(dot(N, L)) * att * _SpotLitColList[n].xyz * _SpotLitColList[n].w;
                }

                return float4(Lo, 1.0);
            }
			
			ENDCG
		}
    }
    FallBack "Diffuse"
}
