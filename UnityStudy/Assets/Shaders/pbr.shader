Shader "Custom/pbr"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _SpecularColor ("SpecularColor", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Roughness ("Roughness", Range(0,1)) = 0.5
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
            float4 _SpecularColor;
            float _Roughness;
            float _Metallic;
            float4 _MainTex_ST;
            float4 _MainLitDir;
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

            float distributionGGX(float3 N, float3 H, float roughness)
            {
                float a = roughness*roughness;
                float a2 = a*a;
                float NoH = max(dot(N, H), 0.0);
                float NoH2 = NoH*NoH;

                float nom = a2;
                float denom = (NoH2 * (a2 - 1.0) + 1.0);
                denom = 3.1415926 * denom * denom;

                return nom / denom;
            }

            float geometrySchlickGGX(float NoV, float roughness)
            {
                float r = (roughness + 1.0);
                float k = (r*r) / 8.0;

                float nom   = NoV;
                float denom = NoV * (1.0 - k) + k;

                return nom / denom;
            }

            float geometrySmith(float3 N, float3 V, float3 L, float roughness)
            {
                float NoV = max(dot(N, V), 0.0);
                float NoL = max(dot(N, L), 0.0);
                float ggx2  = geometrySchlickGGX(NoV, roughness);
                float ggx1  = geometrySchlickGGX(NoL, roughness);

                return ggx1 * ggx2;
            }

            float3 fresnelSchlick(float3 V, float3 H, float3 F0)
            {
                float VoH = max(dot(V, H), 0.0);
                return F0 + (1.0 - F0) * pow(1.0 - VoH, 5.0);
            }

            float3 calcSpecular(float3 N, float3 V, float3 L, float3 H, float3 F0, float roughness)
            {
                float D = distributionGGX(N, H, roughness);
                float G = geometrySmith(N, V, L, roughness);
                float3 F = fresnelSchlick(V, H, F0);
                float3 nom = (D * G) * F;
                float denom = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001; 
                return nom / denom;
            }

            float3 calcDiffuse(float3 diffuseColor)
            {
                return diffuseColor / 3.1415926;
            }

            fixed4 frag(v2f i) : COLOR {
                fixed4 albedo = tex2D(_MainTex, i.uv);
                float3 N = normalize(i.normal);
                float3 V = normalize(i.eyeDir);
                float3 Lo = float3(0.0, 0.0, 0.0);
                {
                    float3 L = normalize(-_MainLitDir.xyz);
                    float3 H = normalize(V + L);
                    float NoL = clamp(dot(N, L), 0.0, 1.0);
                    float illuminance = _MainLitDir.w * NoL;
                    float3 Fd = calcDiffuse(albedo.xyz);
                    float3 Fr = calcSpecular(N, V, L, H, _SpecularColor.xyz, _Roughness);
                    Lo += (Fd + Fr) * illuminance;
                }

                for(int n = 0; n < _SphereLitCount; n++)
                {
                    float3 unnormalizedLightVector = _SphereLitPosList[n].xyz - i.posWorld;
                    float3 L = normalize(unnormalizedLightVector);
                    float3 H = normalize(V + L);
                    float lightInvSqrAttRadius = 1.0 / (_SphereLitPosList[n].w * _SphereLitPosList[n].w);
                    float att = 1.0;
                    att *= getDistanceAtt(unnormalizedLightVector, lightInvSqrAttRadius);
                    float3 Fd = calcDiffuse(albedo.xyz);
                    float3 Fr = calcSpecular(N, V, L, H, _SpecularColor, _Roughness);
                    Lo += (Fd + Fr) * saturate(dot(N, L)) * att * _SphereLitColList[n].xyz * _SphereLitColList[n].w;
                }

                for(int k = 0; k < _SpotLitCount; k++)
                {
                    float3 unnormalizedLightVector = _SpotLitPosList[k].xyz - i.posWorld;
                    float3 L = normalize(unnormalizedLightVector);
                    float3 H = normalize(V + L);
                    float lightInvSqrAttRadius = 1.0 / (_SpotLitPosList[k].w * _SpotLitPosList[k].w);

                    float cosInner = max(dot(-_SpotLitDirList[k].xyz, L), 0.01);
                    float cosOuter = _SpotLitDirList[k].w;
                    float litAngleScale = 1.0 / max(0.001, cosInner - cosOuter);
                    float litAngleOffset = -cosOuter * litAngleScale;
                    float att = 1.0;
                    att *= getDistanceAtt(unnormalizedLightVector, lightInvSqrAttRadius);
                    att *= getAngleAtt(L, -_SpotLitDirList[k].xyz, litAngleScale, litAngleOffset);
                    float3 Fd = calcDiffuse(albedo.xyz);
                    float3 Fr = calcSpecular(N, V, L, H, _SpecularColor, _Roughness);
                    Lo += (Fd + Fr) * saturate(dot(N, L)) * att * _SpotLitColList[k].xyz * _SpotLitColList[k].w;
                }
                
                return float4(Lo, 1.0);
            }
			
			ENDCG
		}
    }
    FallBack "Diffuse"
}
