Shader "Custom/Chapter 7/Single texture" {
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
				//TEXCOORD0语义把第一组纹理坐标存储到该变量中
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				//存放纹理坐标
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = normalize(UnityObjectToWorldDir(v.vertex));
				//使用纹理的属性值_MainTex_ST来对顶点纹理坐标进行变换，计算最终的纹理坐标
				//先使用_MainTex_ST.xy进行缩放，然后使用_MainTex_ST.zw进行偏移
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//可以使用内置宏TRANSFORM_TEX来计算上述过程，内置宏在unityCG.cginc文件里
				//o.uv = TRANSFORM_TEX(v.texcoord, _mainTex)
				return o;
			}
			
			float4 frag(v2f i) : SV_TARGET{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				//使用CG的tex2D对纹理进行采样，参数1以为采样的纹理，参数2为float2类型的纹理坐标，返回纹素值
				//采样结果和颜色属性的乘积作为材质的反射率（albedo）
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				//反射率与环境光乘积计算材质表面环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//反射率参与计算漫反射
				fixed3 diffuse = _LightColor0.rgb *albedo* saturate(dot(worldNormal, worldLightDir));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(viewDir + worldLightDir);
				//采用blinn模型计算镜面反射
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);
				//最后漫反射+镜面反射+环境光得出物体表面的光照
				return fixed4(diffuse + ambient + specular, 1.0);
			}
			ENDCG
		}

	}
	FallBack "Specular"
}
