Shader "Hair/ATIHairSketchPass1" 
{
	Properties 
	{
		_MainTex ("Diffuse (RGB), 8-bit alpha blended transparency (A)", 2D) = "white" {}
	}
	
	SubShader 
	{		
		LOD 300
		
		Name "PrimeZBuffer"
		Tags
		{
			"Queue" = "AlphaTest"
			"IgnoreProjector" = "True"
			"RenderType" = "TransparentCutout"
		}
		Cull Off				// 2 sided hair
		AlphaTest GEqual 1.0	// Only render opaque pixels
		ZWrite On
		ZTest Less
		ColorMask 0				// Disables color buffer writes 
		
		CGPROGRAM
			#include "CustomLighting.cginc"
			#pragma surface surf KajiyaKayMarschner vertex:vert
			#pragma target 3.0
				
			sampler2D _MainTex;
			
			struct Input
			{
				float2 uv_MainTex;
				float3 eyeVec;
				float3 worldBinormal;
			};
	
	        struct v2f 
	        {
	            float4 pos          : SV_POSITION;	// final vert point used for pixel rasterization 
				float2 UV           : TEXCOORD0;
				float3 vertColor    : TEXCOORD1;
	        };
	
			void vert(inout appdata_full v, out Input o)
			{
			    o.uv_MainTex = v.texcoord;
			    
				// v.vertex is the input vertex's world position
				float3 worldPos = mul(_Object2World, v.vertex).xyz;
				
				// Calculate vector from vertex to the view/camera
				o.eyeVec = worldPos - _WorldSpaceCameraPos;
				
				// Calculate world binormal from contents of appdata_full
				float3 binormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
				o.worldBinormal = mul(transpose(_World2Object), float4(binormal, 0)).xyz;
			}
			
			void surf(Input IN, inout SurfaceOutputKKM o)
			{
				// Pull textures and feed into input struct so that the lighting model can read them
				fixed4 Dt = tex2D(_MainTex, IN.uv_MainTex);
				
				o.Albedo = float3(0,0,0);
				o.Alpha = Dt.a;
			}

		ENDCG
    } 
	
//	FallBack "Diffuse"
}

