Shader "Eye/EyePOM"
{
	Properties 
	{
		_Ambient ("Ambient color", Color) = (0.0, 0.0, 0.0, 0.0)
		_CDiffMap ("Cornea diffuse map (RGB), Iris mask (A)", 2D) = "white" {}
		_CSpecColor ("Cornea spec color", Color) = (1.0, 0.85, 0.85, 1.0)
		_CSpecStr ("Cornea specular strength", Range(0.0, 10.0)) = 0.7
		_CSpecGls ("Cornea exponent", Range(0.0, 255.0)) = 25.0		
		_CNormMap ("Cornea normal (RGB), Unusable channel (A)", 2D) = "bump" {}
		
		_IDiffMap ("Iris diffuse map (RGB), Parallax offset map height (A)", 2D) = "white" {}
		_ISpecColor ("Iris spec color", Color) = (0.8, 0.9, 1.0, 1.0)
		_ISpecStr ("Iris specular strength", Range(0.0, 10.0)) = 5.0
		_ISpecGls ("Iris exponent", Range(0.0, 255.0)) = 255.0		
		_IDialation ("Pupil dialation factor", Range(-1.0, 1.0)) = 1.0								// TODO: Add some optional control later to make this automatic when lights come within a certain proximity of the eyes
		_INormMap ("Iris normal (RGB), Unusable channel (A)", 2D) = "bump" {} 
		_IPOMHeight ("Iris POM height", Range(-1.0, 1.0)) = -0.75
		
		_ReflCubeMap ("Cubemap reflection", CUBE) = "" {}
		_ReflStr ("Reflection strength", Range(0.0, 1.0)) = 0.01
		_ReflCnt ("Reflection contrast", Range(0.0, 15.0)) = 1.0
		_ReflFrn ("Fresnel falloff power", Range(0.0, 100.0)) = 1.5
		
		_SDiffMap ("Shadow diffuse map (RGB), Empty channel (A)", 2D) = "white" {}	
		_SMStr ("Shadow map strength", Range(0.0, 1.0)) = 1.0	
	}

	SubShader 
	{
		Tags
		{
			"RenderType" = "Opaque"
		}
		LOD 300
		
		CGPROGRAM
			#include "CustomLighting.cginc"
    		#pragma surface surf ReflectiveEye vertex:vert
    		#pragma target 3.0
//    		#pragma debug

			////////////////////////////////////////
			//     Structs			 	          //
			////////////////////////////////////////
    		struct Input 
    		{
    			// Note that these UV names MUST match the property
				float2 uv_CDiffMap;		
				float2 uv2_IDiffMap;
				float3 t_eyeVec;
				float3 eyeVec;
    		};
    		
			////////////////////////////////////////
			//     Variables		 	          //
			////////////////////////////////////////
    		// Texture maps
    		sampler2D _CDiffMap;
    		sampler2D _IDiffMap; 
    		sampler2D _CNormMap;
    		sampler2D _INormMap;
    		sampler2D _SDiffMap;
			samplerCUBE _ReflCubeMap;
			
			// Floats
    		float _IDialation; 
    		float _CSpecGls; 
    		float _ISpecGls; 
    		float _IPOMHeight;
            float _ReflCnt;
            float _ReflFrn;
            
            // Passed in via script
            uniform float4x4 ViewInverse;
            

			////////////////////////////////////////
			//     Vertex shader    	          //
			////////////////////////////////////////
			void vert(inout appdata_full v, out Input o)
			{				
				// Build object to tangent space transform matrix
				float3x3 objTangentXf;
				objTangentXf[0] = BinormalCalc(v).xyz;
				objTangentXf[1] = -v.tangent.xyz;
				objTangentXf[2] = v.normal.xyz;
								
				float4 objSpaceEyePos = mul(ViewInverse[3], _World2Object);
				float3 objEyeVec = objSpaceEyePos.xyz - v.vertex.xyz;								// Object space eye vector 
				float3 worldSpacePos = mul(v.vertex, _Object2World).xyz;							// Put the vertex in world space
				o.t_eyeVec = mul(objTangentXf, objEyeVec);
				
				o.eyeVec = (ViewInverse[3] - worldSpacePos).xyz;
			    o.uv_CDiffMap = v.texcoord.xy;
			    o.uv2_IDiffMap = v.texcoord1.xy;
			}
            

			////////////////////////////////////////
			//     Surface shader    	          //
			////////////////////////////////////////
    		void surf (Input IN, inout SurfaceOutputRE o)
    		{  
    			// Vector edits    			
    			float3 t_eyeVecRot = float3(-IN.t_eyeVec.y, IN.t_eyeVec.x, IN.t_eyeVec.z);			// Rotate 90 degrees CCW about z-axis: (x, y, z) -> (-y, x, z)
    																								// TODO: put this calculation into the ViewInverseCalculator.cs script
				float3 eyeVecRot = float3(-IN.eyeVec.y, IN.eyeVec.x, IN.eyeVec.z);					// TODO: is this needed?
				
				// Parallax offset texcoords
				float2 t_eyeVec = normalize(t_eyeVecRot).xy;										// Normalize tangent eye vector 
    			float heightAlpha = tex2D(_IDiffMap, IN.uv2_IDiffMap.xy).a * 2 - 2;					// Bring in height and modify to reduce scaling errors during parallaxing
    			float2 IrisUv = IN.uv2_IDiffMap.xy; 
    			IrisUv = (heightAlpha * t_eyeVec * -(_IPOMHeight / 5)) + (IN.uv2_IDiffMap.xy);		// Offset UVs by the height map, depend on view vector
    			
    			// Pupil Dilation done via scaling UVs
				IrisUv.xy -= 0.5;																	// Center UVs to 0, to make math easier
				float pupilRange = saturate(length(IrisUv.xy) / 0.42);								// 0.42 is a "magic number" for the size, should eventually expose this to user, UV dependent.
				float dilationFactor = (_IDialation / 2) + 0.5;										// Moves value to to 0-1 range
			    dilationFactor = saturate(dilationFactor) * 2.5 - 1.25;								// Define dilation range
				IrisUv.xy *= lerp(1.0f, pupilRange, dilationFactor); 								// Here we lerp UVs together, weighted on the dilation factor
				IrisUv.xy += 0.5f;																	// Set UVs back to where they were
    			
    			// Baked shadow map
    			float4 bakedShadow = float4(0, 0, 0, 0);
    			bakedShadow = 1 - tex2D(_SDiffMap, IN.uv_CDiffMap);
    			
    			// Cornea diffuse
    			float4 c = float4(0.5, 0.5, 0.5, 0);												// Default cornea color
				c = tex2D(_CDiffMap, IN.uv_CDiffMap);												// Use cornea map
				
				// Iris diffuse
				float4 irisColor = tex2D(_IDiffMap, IrisUv);
				c = OverlayTextures(c.rgb, irisColor.rgb, c.a);										// Combine cornea and iris diffuse maps
				
				// Glossiness; shoving into a float3 so I can take advantage of the OverlayTextures function
				float3 gloss = float3(_CSpecGls, _CSpecGls, _CSpecGls);								// Set cornea gloss level
				float3 irisGlossColor = float3(_ISpecGls, _ISpecGls, _ISpecGls);					// Set iris gloss level
				gloss = OverlayTextures(gloss, irisGlossColor, c.a).rgb;							// Combine cornea and iris gloss levels
				
				// Normals
				float3 cnormal = UnpackNormal(tex2D(_CNormMap, IN.uv_CDiffMap));
				float3 inormal = UnpackNormal(tex2D(_INormMap, IrisUv));
				float3 N = OverlayTextures(cnormal, inormal, c.a).rgb; 
				
				// Reflection
				float3 reflectmap = float3(1, 1, 1);
				reflectmap = lerp(reflectmap, (reflectmap - bakedShadow), _SMStr * 2);				// Make ambient occlusion remove some cubemap reflections
				float3 reflectionamount = reflectmap * fresnel(cnormal, eyeVecRot, _ReflFrn);		// Start off by getting fresnel falloff
				float3 reflectVector = reflect(t_eyeVecRot, cnormal);								// Compute reflection vector; TODO: eyeVecRot or t_eyeVecRot?
				
				// Final lerps, to blend between fresnel effect and lit color
				reflectVector.yz = -reflectVector.yz; 												// Invert reflectionvector for cubemap sampling
				float3 reflcubemap = texCUBE(_ReflCubeMap, reflectVector).rgb;						// Sample from cubemap with reflection vector
				reflcubemap /= _ReflCnt;															// Cuts down reflection texture
				reflcubemap = pow(reflcubemap, _ReflCnt);											// Adds contrast to reflection texture
				
				o.Albedo = c.rgb;
				o.Alpha = c.a;
				o.Gloss = gloss.r; 
				o.Normal = cnormal;
				o.Emission = pow(irisColor / 2, 2);													// TODO: is there any way to store iris normals here?
				o.Refl = float4(reflcubemap, 1.0);
				o.ReflAmt = float4(reflectionamount, 1.0);
				o.Shadow = (bakedShadow.r + bakedShadow.g + bakedShadow.b) / 3;
    		}
		ENDCG
	}
	
	FallBack "Diffuse"
}
