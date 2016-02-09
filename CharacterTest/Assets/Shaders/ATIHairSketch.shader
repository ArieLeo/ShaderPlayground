Shader "Hair/ATIHairSketch" 
{
	Properties 
	{
		_Color ("Hair color (tint)", Color) = (1.0, 0.0, 0.0, 1.0)
		_MainTex ("Diffuse (RGB), 8-bit alpha blended transparency (A)", 2D) = "white" {}
		_TileVal ("Main UV texture tiling", Range(1.0, 20.0)) = 1.0
		_NormalMap ("Normal wave (RGB), Gloss (A)", 2D) = "bump" {}
        _NormOpac ("Normal map intensity", Range(0.0, 1.0)) = 1.0
        _SpecShift ("Specular shift", Range(-0.5, 1)) = 0.0
        _SpecNoiseScale ("Specular noise scale", Range(0.0, 1.0)) = 1.0
		_SpecTex ("Specular shift (RGB), Specular noise (A)", 2D) = "white" {}
        _SpecTint ("Specular color (RGB)", Color) = (0.5, 0.5, 0.5, 1.0)
        _SpecPower ("Specular power", Range(1.0, 256.0)) = 30.0
        _SpecSharp ("Specular edge sharpness", Range(0.0, 1.0)) = 0.85
        _SpecExp ("Specular fresnel exponent", Range(0.0, 5.0)) = 0.0
        _SpecScale ("Specular fresnel multiplier", Range(1.0, 15.0)) = 1.0
		_CubeMap ("Cubemap reflection", CUBE) = "" {}
		_ReflOpac ("Reflection opacity", Range(0.0, 1.0)) = 0.05
		_RimPower("Rim Power", Range(0.01, 4.0)) = 1.5
        _RimOpacity("Rim opacity", Range(0.0, 1.0)) = 1.0
	}
	
	SubShader 
	{		
		LOD 300
		
		Pass 
		{	
			Name "PrimeZBuffer"	
			Tags
			{
				"Queue" = "AlphaTest"
				"IgnoreProjector" = "True"
				"RenderType" = "TransparentCutout"
			}
			Cull Off	// 2 sided hair
			AlphaTest GEqual 1.0	// Only render opaque pixels
			ZWrite On
			ZTest Less
			ColorMask 0		// Disables color buffer writes
			
			CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma fragmentoption ARB_precision_hint_nicest
                #include "UnityCG.cginc"
                
				struct v2f 
                {
                    float4 pos          : SV_POSITION;	// final vert point used for pixel rasterization 
    				float2 UV           : TEXCOORD0;
                };
 
                v2f vert(appdata_full IN)
                {                    
					v2f OUT;
					
					OUT.pos = mul(UNITY_MATRIX_MVP, IN.vertex);
					OUT.UV = IN.texcoord;
										
					return OUT;
                }
                
                sampler2D _MainTex;
                float4 _Color;
                
				half4 frag(v2f i) : COLOR
                {
                	half4 c = tex2D(_MainTex, i.UV);
                	
                	// Simple pixel shader that just returns alpha
                    return half4(half3(0, 0, 0), c.a);
                }
			
			ENDCG
		}
		
		Pass
        {
            Name "RenderOpaqueRegions"
            Tags
			{
				"Queue" = "Geometry"
				"IgnoreProjector" = "True"
				"RenderType" = "Opaque"
			}
			Cull Off	// 2 sided hair
			AlphaTest GEqual 1.0	// Only render opaque pixels
			ZWrite Off
			ZTest Equal
			
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma fragmentoption ARB_precision_hint_nicest
                #include "UnityCG.cginc"
 
                struct v2f 
                {
                    float4 pos          : SV_POSITION;	// final vert point used for pixel rasterization 
    				float2 UV           : TEXCOORD0;
    				float3 vertColor    : TEXCOORD1;
                };
 
                v2f vert(appdata_full IN)
                {                    
					v2f OUT;
					
					OUT.vertColor = IN.color.rgb;
					
					OUT.pos = mul(UNITY_MATRIX_MVP, IN.vertex);
					OUT.UV = IN.texcoord;
										
					return OUT;
                }
 
                sampler2D _MainTex;
                float4 _Color;
 
                half4 frag(v2f i) : COLOR
                {
                	half4 c = tex2D(_MainTex, i.UV);
                	// clip(c.a - 1);	// Don't render any pixels that aren't fully opaque
                	
                    return half4(c.rgb * _Color.rgb, c.a);
                }
            ENDCG          
        }
        
		Pass
        {
            Name "RenderTransparentBackfaces"
            Tags
			{
				"Queue" = "Transparent"
				"IgnoreProjector" = "True"
				"RenderType" = "Transparent"
			}
			Cull Front
			ZWrite Off
			ZTest Less
			Blend SrcAlpha OneMinusSrcAlpha
			
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma fragmentoption ARB_precision_hint_nicest
                #include "UnityCG.cginc"
 
                struct v2f 
                {
                    float4 pos          : SV_POSITION;	// final vert point used for pixel rasterization 
    				float2 UV           : TEXCOORD0;
    				float3 vertColor    : TEXCOORD1;
                };
 
                v2f vert(appdata_full IN)
                {                    
					v2f OUT;
					
					OUT.vertColor = IN.color.rgb;
					
					OUT.pos = mul(UNITY_MATRIX_MVP, IN.vertex);
					OUT.UV = IN.texcoord;
										
					return OUT;
                }
 
                sampler2D _MainTex;
                float4 _Color;
 
                half4 frag(v2f i) : COLOR
                {
                	half4 c = tex2D(_MainTex, i.UV);
                	
                    return half4(c.rgb * _Color.rgb, c.a);
                }
            ENDCG          
        }
        
		Pass
        {
            Name "RenderTransparentFrontFaces"
            Tags
			{
				"Queue" = "Transparent"
				"IgnoreProjector" = "True"
				"RenderType" = "Transparent"
			}
			Cull Back
			ZWrite On
			ZTest Less
			Blend SrcAlpha OneMinusSrcAlpha
			
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma fragmentoption ARB_precision_hint_nicest
                #include "UnityCG.cginc"
 
                struct v2f 
                {
                    float4 pos          : SV_POSITION;	// final vert point used for pixel rasterization 
    				float2 UV           : TEXCOORD0;
    				float3 vertColor    : TEXCOORD1;
                };
 
                v2f vert(appdata_full IN)
                {                    
					v2f OUT;
					
					OUT.vertColor = IN.color.rgb;
					
					OUT.pos = mul(UNITY_MATRIX_MVP, IN.vertex);
					OUT.UV = IN.texcoord;
										
					return OUT;
                }
 
                sampler2D _MainTex;
                float4 _Color;
 
                half4 frag(v2f i) : COLOR
                {
                	half4 c = tex2D(_MainTex, i.UV);
                	
                    return half4(c.rgb * _Color.rgb, c.a);
                }
            ENDCG          
        }
            
//		Tags
//		{
//			"Queue" = "Geometry"
//			"IgnoreProjector" = "True"
//			"RenderType" = "Opaque"
//		}
//		Cull Off	// 2 sided hair
//		
//		CGPROGRAM
//			#include "CustomLighting.cginc"
//			#pragma surface surf KajiyaKayMarschner vertex:vert
//			#pragma target 3.0
//				
//			sampler2D _MainTex;
//			sampler2D _NormalMap;
//			sampler2D _SpecTex;
//			samplerCUBE _CubeMap;
//			float _ReflOpac;
//			fixed4 _Color;
//			fixed4 _SpecTint;
//			
//			struct Input
//			{
//				float2 uv_MainTex;
//				float3 eyeVec;
//				float3 worldBinormal;
////				float3 worldRefl;
////				INTERNAL_DATA
//			};
//
//            struct v2f 
//            {
//                float4 pos          : SV_POSITION;	// final vert point used for pixel rasterization 
//				float2 UV           : TEXCOORD0;
//				float3 vertColor    : TEXCOORD1;
//            };
//
//			void vert(inout appdata_full v, out Input o)
//			{
//			    o.uv_MainTex = v.texcoord;
//			    
//				// v.vertex is the input vertex's world position
//				float3 worldPos = mul(_Object2World, v.vertex).xyz;
//				
//				// Calculate vector from vertex to the view/camera
//				o.eyeVec = worldPos - _WorldSpaceCameraPos;
//				
//				// Calculate world binormal from contents of appdata_full
//				float3 binormal = cross(v.normal, v.tangent.xyz) * v.tangent.w;
//				o.worldBinormal = mul(transpose(_World2Object), float4(binormal, 0)).xyz;
//			}
//			
//			void surf(Input IN, inout SurfaceOutputKKM o)
//			{
//				// Pull textures and feed into input struct so that the lighting model can read them
//				fixed4 Dt = tex2D(_MainTex, IN.uv_MainTex);
//				fixed4 Nt = tex2D(_NormalMap, IN.uv_MainTex);
//				fixed4 St = tex2D(_SpecTex, IN.uv_MainTex);
//				
//				o.Albedo = Dt.rgb * _Color.rgb;
//				o.Alpha = Dt.a;
//				o.Normal = UnpackNormal(Nt);
//				o.SpecNoise = St.a;
//				o.Gloss = Nt.a;
////				o.Emission = _ReflOpac * texCUBE(_CubeMap, WorldReflectionVector(IN, o.Normal)).rgb;
//				o.V = normalize(IN.eyeVec);
//				o.Bw = normalize(IN.worldBinormal);
//				o.Specular = St.rgb;
//			}
//
//		ENDCG
	}
	
	FallBack "Diffuse"
}

