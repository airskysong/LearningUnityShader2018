//一个简单的顶点和片元着色器shader
Shader "Custom/Chapter 5/Simple shader" //Shader语义定义了UnityShader的名字，并且方便材质球选择Shader时快速找到自定义的Shader
{
	Subshader{
	Pass{	//声明了SubShader和Pass语义块
			CGPROGRAM	//声明CGPROGRAM，在ENDCG中的代码将使用CG/HLSL代码片段
			//使用#pragma将告诉Unity哪个函数包含了顶点着色器（vertex）的代码，哪个函数包含了（frag）片元着色器的代码
			#pragma vertex vert
			#pragma fragment frag
			//POSTION和SV_POSITION都是CG/HLSL中的语义，：POSITION语义指定了变量v接收顶点位置，：SV_POSITION语义告诉Unity输出是裁剪空间坐标
			float4 vert(float4 v : POSITION) : SV_POSITION{
				return UnityObjectToClipPos(v);//默认包含的UnityCG.cginc库里的UnityObjectToClipPos(float3 pos)可以将将顶点从模型空间坐标转换到裁剪空间坐标
			}
			//frag函数没有任何输入，输出一个fixed4类型的变量，SV_Target也是HLSL中的一个系统语义，告诉渲染器把用户输入颜色存储到一个渲染目标（render target）中，这里将默认输出到默认的帧缓存中，片元着色器输出的颜色的每个分量范围在【0,1】，（0,0,0）表示黑色，而（1,1,1）表示白色
			float4 frag() : SV_TARGET{
				return fixed4(1.0,1.0,1.0,1.0);
			}
			ENDCG
		}
	}
}
