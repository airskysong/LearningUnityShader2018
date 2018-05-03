Shader "Custom/Chapter 8/Alpha blend"{
	Properties{
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_AlphaTex("AlphaTexture", 2D) = "white"{}
		_AlphaScale("AlphaScale", Range(0, 1)) = 1
	}
	SubShader{
		Tags{"Queue"="Transparent""IgnoreProjector"="True""RenderType"="Transparent"}
		pass{

			Tags{"LightMode"="ForwardBase"}	
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _AlphaTex;
			float4 _AlphaTex_ST;
			fixed _AlphaScale;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f{
				float4 vertex : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldPos = UnityObjectToWorldDir(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _AlphaTex);
				
				return o;
			}

			fixed4 frag(v2f o) : SV_Target{
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(o.worldPos));

				fixed4 texColor = tex2D(_AlphaTex, o.uv);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(o.worldNormal, worldLightDir));

				return fixed4(diffuse + ambient,texColor.a * _AlphaScale);
			}

			ENDCG
		}
	}
	Fallback "Transparent/VertexLit"
}