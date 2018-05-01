//逐像素光照，把光照的计算放在片元函数里
Shader "Custom/Chapter 6/Diffuse Pixel-Level"
{
	//语义声明了一个Color类型的属性，并把它的初设值设为白色
	Properties{
		_Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader{
		pass{
			//只有定义了正确的光照模式，才能得到Unity里特定的数值
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#include "Lighting.cginc"
			//
			fixed4 _Diffuse;
			
			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 normal : TEXCOORD0;
			};
			
			#pragma vertex vert
			#pragma fragment frag
			
			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//把模型空间法线向量转换到世界坐标空间法线向量并且归一化
				o.normal = normalize(mul(v.normal, unity_WorldToObject));
				return o;
			}
			fixed4 frag(v2f i) : SV_TARGET{
				//取得环境光颜色
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//光源方向可以由内置变量_WorldSpaceLightPos0得到
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//漫反射光照模型：diffuse = lightcolor.rgb * diffuse.rgb * max(0, dot(i.normal, worldLight));
				//UNITY内置变量_LightColor0可以访问该pass处理的光源的颜色和强度信息，需要定义合适的LightMode标签
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(i.normal, worldLight));
				fixed3 color = ambient + diffuse;
				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}