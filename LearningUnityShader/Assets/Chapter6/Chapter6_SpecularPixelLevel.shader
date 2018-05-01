//逐像素光照
Shader "Custom/Chapter 6/Specular Pixel-Level"
{
	//分别声明了漫反射颜色，高光颜色，高光区域大小
	Properties{
		_Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
	SubShader{
		pass{
			//只有定义了正确的光照模式，才能得到Unity里特定的数值
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#include "Lighting.cginc"
			//
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
				fixed3 worldPos : TEXCOORD1;
			};
			
			#pragma vertex vert
			#pragma fragment frag
			
			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//把模型空间法线向量转换到世界坐标空间法线向量并且归一化
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				o.worldNormal = worldNormal;
				o.worldPos = UnityObjectToWorldDir(v.vertex).xyz;
				return o;
			}
			fixed4 frag(v2f i) : SV_TARGET{
				//取得环境光颜色
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//光源方向可以由内置变量_WorldSpaceLightPos0得到
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//UNITY内置变量_LightColor0可以访问该pass处理的光源的颜色和强度信息，需要定义合适的LightMode标签
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(i.worldNormal, worldLightDir));
				//获取在世界空间下的反射方向，在CG的reflect函数里的入射方向由光源指向交点的，故取反向
				fixed3 reflectDir = reflect(-worldLightDir, i.worldNormal);
				//取得在世界空间下的视图方向
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				//计算高光反射
				fixed3 specular = _LightColor0.rgb *_Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);
				fixed3 color = ambient + diffuse + specular;
				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}