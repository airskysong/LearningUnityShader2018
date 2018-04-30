//顶点着色器和片元着色器的通信, 显示物体的法线颜色
Shader "Custom/Chapter 5/Simple shader 3"
{
	Subshader{
	Pass{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		//使用一个结构体来定义顶点着色器的输入
		struct a2v {
			//POSITION语义告诉Unity，用模型空间的顶点坐标填充vertex变量
			float4 vertex : POSITION; 
			//NORMAL语义告诉Unity，用模型空间的法线方向填充normal变量
			float3 normal : NORMAL;
			//TEXCOORD0语义告诉Unity，用模型的第一套纹理坐标填充texcoord变量
			float4 texcood : TEXCOORD0;	
		};
		//使用一个结构体来定义顶点着色器的输出
		struct v2f{
			//存储裁剪空间中位置的信息
			float4 pos : SV_POSITION;
			//存储颜色信息
			fixed3 color : COLOR0;
		};

		v2f vert(a2v v){
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
			return o;
		}
		fixed4 frag(v2f i) : SV_TARGET{
			//将插值后的i.color显示到屏幕上
			return fixed4(i.color, 1);
		}
		ENDCG
		}
	}
}
