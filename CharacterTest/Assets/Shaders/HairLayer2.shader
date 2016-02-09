Shader "Hair/HairLayer2" 
{
	Properties 
	{
		_Color("Main Color", Color) = (1,0.3731343,0.3731343,1)
		_MainTex("Base (RGB) Transparent (A)", 2D) = "white" {}
		_NormalMap ("Normalmap", 2D) = "bump" {}
		_SpecG ("Spec (RGB) Gloss (A)", 2D) = "grey" {}
		_AnisoTex ("Anisotropic Direction (Normal)", 2D) = "bump" {}
		_AnisoOffset ("Anisotropic Highlight Offset", Range(-1,1)) = -0.2
	}

	SubShader 
	{
		Tags
		{
			"Queue" = "Transparent+2" // Second hair layer; reduces artifacting by having hair layers in separate render queues
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
		#pragma surface surf Aniso alpha
		// for transparency, #pragma surface surf Aniso alpha
		#pragma target 3.0
		#pragma debug
		
		float _AnisoOffset;
		
		struct SurfaceOutputAniso 
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed4 AnisoDir;
			fixed3 Emission;
			fixed3 Specular;
			fixed Gloss;
			fixed Alpha;
		};
		
		inline fixed4 LightingAniso (SurfaceOutputAniso s, fixed3 lightDir, fixed3 viewDir, fixed atten)
		{
			fixed3 h = normalize(normalize(lightDir) + normalize(viewDir));
			float NdotL = saturate(dot(s.Normal, lightDir));
			
			fixed HdotA = dot(normalize(s.Normal + s.AnisoDir.rgb), h);
			float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
			
			float spec = saturate(dot(s.Normal, h));
			spec = saturate(pow(lerp(spec, aniso, s.AnisoDir.a), s.Gloss * 128) * s.Specular);
			
			fixed4 c;
			c.rgb = ((s.Albedo * _LightColor0.rgb * NdotL) + (_LightColor0.rgb * spec)) * (atten * 2);
			c.a = s.Alpha;
			
			return c;
		}


		float4 _Color;
		sampler2D _MainTex;		
		sampler2D _NormalMap;
		sampler2D _SpecG;
		sampler2D _AnisoTex;
		
		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_AnisoTex;
		};
		
		void surf (Input IN, inout SurfaceOutputAniso o) 
		{		
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			fixed4 spec = tex2D(_SpecG, IN.uv_MainTex.xy);
			
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
			o.Specular = spec.rgb;
			o.Gloss = spec.a;
			o.Emission = 0.0;
			o.AnisoDir = fixed4(UnpackNormal(tex2D(_AnisoTex, IN.uv_AnisoTex)), spec.b);
		}
		ENDCG
	}
	
	FallBack "Transparent/Diffuse"
}
