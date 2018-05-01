//逐顶点光照
Shader "Custom/Chapter 6/Diffuse Vertex-Level"
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
				fixed3 color : COLOR;
			};
			
			#pragma vertex vert
			#pragma fragment frag
			
			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//取得环境光颜色
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//把模型空间法线向量转换到世界坐标空间法线向量并且归一化，逆矩阵只需要取前三行前三列就可以了
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				//光源方向可以由内置变量_WorldSpaceLightPos0得到
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//漫反射光照模型：diffuse = lightcolor.rgb * diffuse.rgb * max(0, dot(i.normal, worldLight));
				//UNITY内置变量_LightColor0可以访问该pass处理的光源的颜色和强度信息，需要定义合适的LightMode标签
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));
				o.color = ambient + diffuse;
				return o;
			}
			fixed4 frag(v2f i) : SV_TARGET{
				return fixed4(i.color, 1.0);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}