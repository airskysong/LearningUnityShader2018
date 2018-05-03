//世界空间下计算法线贴图
Shader "Custom/Chapter 7/Normalmap in world space" {
	Properties {
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex("MainTex", 2D) = "white"{}
		_BumpTex("NormalMap", 2D) = "bump"{}
		_BumpScale("BumpScale", float) = 1
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		pass{
			Tags { "LightModel"="ForwardBase" }
			CGPROGRAM
			#include "Lighting.cginc"

			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpTex;
			float4 _BumpTex_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpTex_ST.xy + _BumpTex_ST.zw;

				fixed3 worldPos = UnityObjectToWorldDir(v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				return o;
			}

			float4 frag(v2f i) : SV_TARGET{
				//获取顶点坐标
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed4 packedNormal = tex2D(_BumpTex, i.uv.zw);
				fixed3 tangentNormal;
				//取得切线空间上的法线，注意UpackNormal是UNITY的内置函数，用于解压压缩过的法线贴图并取得在切线空间下的法线向量
				//只有该法线贴图在Unity经过转换即压缩过（在检视面板中标识为normalmap）了才能使用UnpackNormal函数取得正确的切线空间法线方向
				tangentNormal = UnpackNormal(packedNormal);
				//切线空间上的法线乘以_BumpScle控制凹凸程度
				tangentNormal.xy *= _BumpScale;
				//因为tangentNormal是单位向量，可以由xy分量算出对应的z分量
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				//把切线法线向量转换到世界空间下，注意这里的点乘，等于行列的点乘，相当于做矩阵变换
				tangentNormal = normalize(half3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal), dot(i.TtoW2.xyz, tangentNormal)));
				//对纹理贴图_MainTex进行采样，乘以主颜色得到反射率
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, lightDir));
				fixed3 halfdir = normalize(viewDir + lightDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfdir)), _Gloss);

				return float4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}

	}
	FallBack "Specular"
}
