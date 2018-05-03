Shader "Custom/Chapter 8/Alpha test"{
	Properties{
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex("MainTex", 2D) = "white"{}
		_CutOff("CutOff", Range(0, 1)) = 0.5
	}
	SubShader{
		Tags{"Queue"="AlphaTest""IgnoreProjector"="Yes""RenderType"="TransparentCutout"}
		pass{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#include "Lighting.cginc"
			#pragma vertex vert
			#pragma fragment frag

			fixed3 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _CutOff;

			struct a2v{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
			};
			struct v2f{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = UnityObjectToWorldDir(v.vertex).xyz;
				o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				return o;
			}

			fixed4 frag(v2f o) : SV_Target{
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(o.worldPos));
				float4 texColor = tex2D(_MainTex, o.uv);
				clip(texColor.a - _CutOff);
				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldLightDir, o.worldNormal));
				return fixed4(ambient + diffuse, 1.0);
			}
			ENDCG
		}
	}
	Fallback "Transparent/VertexLit"
}