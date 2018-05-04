//前向渲染，漫反射和镜面反射使用blinn-phong模型
Shader "Custom/Chapter 9/ForwardRendering"
{
	//分别声明了漫反射颜色，镜面颜色，高光区域大小
	Properties{
		_Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
	SubShader{
		Tags{"RenderType"="Opaque"}
		//Base pass
		pass{
			//只有定义了正确的光照模式，才能得到Unity里特定的数值
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM

			//该指令可以保证我们在Shader中使用光照衰减等光照变量可以正确赋值
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag	

			#include "Lighting.cginc"

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

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//使用Unity的帮助函数转换模型空间的法线至世界空间
				fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldNormal = worldNormal;
				o.worldPos = UnityObjectToWorldDir(v.vertex).xyz;
				return o;
			}
			fixed4 frag(v2f i) : SV_TARGET{
				//取得环境光颜色
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//光源方向可以由内置变量_WorldSpaceLightPos0得到
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//计算漫反射
				//UNITY内置变量_LightColor0可以访问该pass处理的光源的颜色和强度信息，需要定义合适的LightMode标签
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(i.worldNormal, worldLightDir));
				//使用Unity的帮助函数计算世界空间的视图方向
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				//计算blinn半方向，半方向为视图方向和入射光方向的和的归一化
				fixed3 halfDir = normalize(viewDir + worldLightDir);
				//使用blinn模型计算镜面反射
				fixed3 specular = _LightColor0.rgb *_Specular.rgb * pow(saturate(dot(halfDir, i.worldNormal)), _Gloss);
				//光源衰减
				fixed atten = 1.0;
				fixed3 color = ambient + (diffuse + specular) * atten;
				return fixed4(color, 1.0);
			}
			ENDCG
		}
		//Additional Pass
		pass{
			Tags{"LightMode"="ForwardAdd"}
			Blend One One
			
			CGPROGRAM

			#pragma multi_compile_fwdadd

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

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

			
			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//使用Unity的帮助函数转换模型空间的法线至世界空间
				fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldNormal = worldNormal;
				o.worldPos = UnityObjectToWorldDir(v.vertex).xyz;
				return o;
			}
			fixed4 frag(v2f i) : SV_TARGET{

				//光源方向可以由内置变量_WorldSpaceLightPos0得到
				//如果当前前向渲染Pass处理的光源类型为平行光，底层渲染引擎就会定义UING_DIRECTIONAL_LIGHT
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				//计算漫反射
				//UNITY内置变量_LightColor0可以访问该pass处理的光源的颜色和强度信息，需要定义合适的LightMode标签
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(i.worldNormal, worldLightDir));
				//使用Unity的帮助函数计算世界空间的视图方向
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				//计算blinn半方向，半方向为视图方向和入射光方向的和的归一化
				fixed3 halfDir = normalize(viewDir + worldLightDir);
				//使用blinn模型计算镜面反射
				fixed3 specular = _LightColor0.rgb *_Specular.rgb * pow(saturate(dot(halfDir, i.worldNormal)), _Gloss);

				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
				#else
					#if defined (POINT)
				        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #elif defined (SPOT)
				        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;
				    #endif
				#endif
				return fixed4((diffuse + specular) * atten, 1.0);
			}
			ENDCG
		}
	}
	Fallback "Specular"
}