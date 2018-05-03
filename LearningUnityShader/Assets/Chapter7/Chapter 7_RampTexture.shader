﻿//渐变纹理
Shader "Custom/Chapter 7/Ramp texture" {
	Properties {
		_Color ("Color Tint", Color) = (1,1,1,1)
		_RampTex("RampTex", 2D) = "white"{}
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		_Gloss("Gloss", Range(8.0,256)) = 20
	}
	SubShader {
		pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
						
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _RampTex;
			fixed4 _RampTex_ST;
			float4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0; 
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = UnityObjectToWorldDir(v.vertex);
				return o;
			}

			float4 frag(v2f i) : SV_TARGET{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
				//渐变纹理在纹理采样的时候使用半兰伯特构建纹理坐标，乘以颜色得到漫反射颜色
				fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb; 
				//与光照颜色相乘得到最后的漫反射颜色
				fixed3 diffuse = _LightColor0.rgb * diffuseColor;
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfdir = normalize(worldViewDir + worldLightDir);
				//渐变纹理镜面反射使用半兰伯特模型
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfdir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			ENDCG
		}

	}
	FallBack "Specular"
}
