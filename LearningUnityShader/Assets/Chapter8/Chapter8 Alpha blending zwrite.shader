Shader "Custom/Chapter 8/Alpha blending zwrite"{
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "white"{}
		_AlphaScale("AlphaScale", Range(0, 1)) = 1
	}
	SubShader{
		Tags{"Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		
		Pass{
		ZWrite on
		ColorMask 0	
		}

		Pass{
			Tags{"LightMode"="ForwardBase"}
			ZWrite off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#include "Lighting.cginc"

			#pragma vertex vert
			#pragma fragment frag

			fixed3 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _AlphaScale;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2; 
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldPos = UnityObjectToWorldDir(v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				
				return o;
			}

			fixed4 frag(v2f o) : SV_TARGET{
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(o.worldPos));
				float4 texColor = tex2D(_MainTex, o.uv);
				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldLightDir, o.worldNormal));

				return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
			}

			ENDCG
		}
		
	}
	Fallback "Transparent/VertexLit"
}