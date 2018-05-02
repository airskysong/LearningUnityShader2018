//切线空间下计算法线贴图
Shader "Custom/Chapter 7/Normal map in tangent space" {
	Properties {
		_Color ("Color Tint", Color) = (1,1,1,1)
		_MainTex ("MainTex", 2D) = "white" {}
		//Bump默认为Unity内置的法线纹理
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
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
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			float4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				//TANGENT语义描述float4类型的Tangent变量，告诉UNITY把顶点的切线方向填充到tangent变量中
				//Tangent和Normal数据类型的不同之处在于Tangent额外存储了切线空间下的第三个坐标轴-副切线的方向性
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0; 
			};
			//由于在片元着色器中处理法线贴图使用了UNITY内置的UnpackNormal函数可以方便地取得切线空间法线，故不用在顶点着色器中传递法线向量
			struct v2f{
				float4 pos : SV_POSITION;
			//由于使用了两个纹理，需要存储两个纹理坐标，故定义类型为float4类型，xy分量存储_MainTex纹理坐标，而zw存储_BumpMap的纹理坐标
			//实际情况里，_MainTex和_BumpMap通常会使用同一组纹理坐标，出于减少插值寄存器的使用数目的目的，只计算和存储一个纹理坐标即可
				float4 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				//根据模型空间下的法线向量与切线向量的点乘计算副切线向量，切线方向的w分量决定了切线方向的朝向
				//fixed3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				//按照切线向量等于X轴，副切线向量等于Y轴，法线向量等于Z轴构建模型空间到切线空间的转换矩阵
				//float3x3 rotationMatrix = float3x3(v.tangent.xyz, binormal, v.normal);
				//也可以使用UNITY的内置宏计算出转换矩阵，结果存储在一个默认变量rotation里，内置宏的位置在unityCG.cginc中，与上面的算法一样
				TANGENT_SPACE_ROTATION;
				//计算切线空间下顶点的光照方向
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex).xyz);
				//计算切线空间下顶点的视图方向
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex).xyz);
				return o;
			}

			float4 frag(v2f i) : SV_TARGET{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//对法线贴图进行采样，取得法线贴图的纹素，注意这一步只能在片元着色器中实现
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;
				//取得切线空间上的法线，注意UpackNormal是UNITY的内置函数，用于解压压缩过的法线贴图并取得在切线空间下的法线向量
				//只有该法线贴图在Unity经过转换即压缩过（在检视面板中标识为normalmap）了才能使用UnpackNormal函数取得正确的切线空间法线方向
				tangentNormal = UnpackNormal(packedNormal);
				//切线空间上的法线乘以_BumpScle控制凹凸程度
				tangentNormal.xy *= _BumpScale;
				//因为tangentNormal是单位向量，可以由xy分量算出对应的z分量
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				//对纹理贴图_MainTex进行采样，乘以主颜色得到反射率
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));
				fixed3 halfdir = normalize(tangentViewDir + tangentLightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfdir)), _Gloss);
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			ENDCG
		}

	}
	FallBack "Specular"
}
