Shader "Hair/HairVersion1.0" 
{
	Properties 
	{
		_Color("Main Color", Color) = (1,0.3731343,0.3731343,1)
		_MainTex("Base (RGB) Transparent (A)", 2D) = "white" {}
		_NormalMap ("Normalmap", 2D) = "bump" {}
		_SpecG ("Spec (RGB) Gloss (A)", 2D) = "grey" {}
	}

	SubShader 
	{
		Tags
		{
			"Queue" = "Transparent+1" // First hair layer; reduces artifacting by having hair layers in separate render queues
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		LOD 300
			
		Cull Off	// 2 sided hair
		ZWrite On
		ZTest LEqual
		ColorMask RGBA
		Blend SrcAlpha OneMinusSrcAlpha
		Fog
		{
		}
		
		CGPROGRAM
		#pragma surface surf Lambert alpha


		float4 _Color;
		sampler2D _MainTex;		
		sampler2D _NormalMap;
		sampler2D _SpecG;
		
		struct Input 
		{
			float2 uv_MainTex;
		};
		
		void surf (Input IN, inout SurfaceOutput o) 
		{
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
			o.Specular = tex2D(_SpecG, IN.uv_MainTex.xy);
			o.Emission = 0.0;
			o.Gloss = 0.0;
		}
		ENDCG
	}
	
	FallBack "Transparent/Diffuse"
}
