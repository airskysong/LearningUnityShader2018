Shader "Custom/Chapter 7/singleTexture" {
	Properties {
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex("Main Tex", 2D) = "white"{}
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		_Gloss("Gloss", range(8.0, 256)) = 20
	}
	SubShader {
		pass
		{
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			//在UNITY中需要使用纹理名_ST的方式来声明某个纹理的属性
			float4 _MainTex_ST;
			fixed4 _Specular;
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
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = normalize(UnityObjectToWorldDir(v.vertex));
				//可以使用内置宏TRANSFORM_TEX来计算上述过程
				//o.uv = TRANSFORM_TEX(v.texcoord, _mainTex)
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				return o;
			}
			
			float4 frag(v2f i) : SV_TARGET{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb *albedo* saturate(dot(worldNormal, worldLightDir));

				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(viewDir + worldLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);
				return fixed4(diffuse + albedo + specular, 1.0);
			}
			ENDCG
		}

	}
	FallBack "Specular"
}
