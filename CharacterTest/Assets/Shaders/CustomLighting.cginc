#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

////////////////////////////////////////
//     Animation Functions		      //
////////////////////////////////////////
float4 Animate2DTex(uniform sampler2D tex, float targetFPS, float rows, float cols, float2 uvs)
{
	// Determine which frame should be showed for a given second
	// Multiplying the _Time.y (s) by FPS (f/s) yields f; the ceiling is used to make sure the result always corresponds to an integer frame
	float curFrame = ceil(_Time.y * targetFPS);				
	float curRow = ceil(curFrame / rows);				
	float curCol = fmod(curFrame, rows);
	
	// Since we're using vertical sprite sheets, the U/X component is 1.0 where the V/Y is adjusted based on the number of frames
	float2 scale = float2(1 / cols, 1 / rows);
				
	// Center of scaling operation is centered in U/X and 
	// F#1 = 1.0 (top of image), F#_Frames = 0.0 (bottom of image) 
	// F#x is offset from 1.0 (top) based on the height of 1 frame (1 / (_Frames - 1)) multiplied by its frame # offset from 1 (curFrame - 1)
	float2 scaleCenter = float2(((1 / (cols - 1)) * (curCol - 1)), 1.0 - ((1 / (rows - 1)) * (curRow - 1)));
	
	// Calculate UVs based on original UVs, the computed center, and scale ratio
	float2 scaledUVs = (uvs - scaleCenter) * scale + scaleCenter;
	
	return tex2D(tex, scaledUVs);
}


////////////////////////////////////////
//     Post Processing Functions      //
////////////////////////////////////////

float4 Desaturate(fixed4 curPixel, float saturationAmt) 
{
	float3 result = lerp(curPixel.rgb, dot(float3(0.3, 0.59, 0.11), curPixel).xxx, saturationAmt);
	
	return float4(result, 1);
}


////////////////////////////////////////
////////////////////////////////////////
//     Lighting Models		          //
////////////////////////////////////////
////////////////////////////////////////

////////////////////////////////////////
//     Half Lambert Rim 	          //
////////////////////////////////////////

// Rim light properties
fixed _RimPower;

// Declare custom lighting models
inline fixed4 LightingHalfLambertRim(SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten)
{
    // Calculate the half vector
    fixed3 halfVector = normalize(lightDir + viewDir);
    
    // Diffuse lighting
    fixed NdotL = max(0, dot(s.Normal, lightDir));
    
    // Calculating specular value and NdotH (normal with half vector)
    fixed EdotH = max(0, dot(viewDir, halfVector));
    fixed NdotH = max(0, dot(s.Normal, halfVector));
    fixed NdotE = max(0, dot(s.Normal, viewDir));
    
    // Half Lambert
    fixed halfLambert = pow((NdotL * 0.5 + 0.5), 2.0);
    
    // Rim Light and pow clamping; multiplying with NdotH makes it so rim light only occurs where light hits model
    fixed rimLight = 1 - NdotE;
    rimLight = pow(rimLight, _RimPower) * NdotH;
    
    fixed4 finalColor;
    finalColor.rgb = (s.Albedo * _LightColor0.rgb + rimLight) * (halfLambert * atten * 2);
    finalColor.a = 0.0;
    
    return finalColor;
}
		
		
////////////////////////////////////////
//     Anisotropic Lighting           //
////////////////////////////////////////

// Lighting properties
float _AnisoOffset;

// Lighting structs
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
		
// Model
inline fixed4 LightingAniso(SurfaceOutputAniso s, fixed3 lightDir, fixed3 viewDir, fixed atten)
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


////////////////////////////////////////
//     ATI HairSketch                 //
//	   (Kajiya-Kay/Marschner)         //
////////////////////////////////////////

// Kajiya-Kay diffuse term sin(T, L) looks too bright without proper self-shadowing
// Instead, use scaled and biased N·L term: diffuse = max(0, 0.75 ∗ N ⋅L + 0.25) 
// Brightens up areas facing away from the light when compared to plain N·L term 
// Simple subsurface scattering approximation, softer look 
float3 lambertHair(float3 L, float3 N)
{
	return smoothstep(-0.1, 0.75, lerp(0.25, 1.0, dot(N, L)));
}

// Hair specular function based on tangent or binormal direction
float3 kajiyaKay(float3 N, float3 Bn, float3 V, float3 L, float specNoise)
{
	float3 B = normalize(Bn + N * specNoise);
	float3 H = normalize(L + V);
	return sqrt(1-pow(dot(B,H),2));
}

// Lighting properties
float _SpecShift;
float _SpecNoiseScale;
float _SpecSharp;
float _SpecPower;
fixed4 _Color;
fixed4 _SpecTint;
float _SpecOpac;

// Lighting structs
struct SurfaceOutputKKM 
{
	fixed3 Albedo;
	fixed3 Normal;
	float3 NormalBasic;
	fixed3 Emission;
	fixed3 Specular;
	fixed Gloss;
	fixed Alpha;
	fixed SpecNoise;
//	float3 V;
	float3 Bw;
};

// This is the lighting model that I'll be evolving into KajiyaKay/Marschner
inline fixed4 LightingKajiyaKayMarschner(SurfaceOutputKKM s, fixed3 lightDir, half3 viewDir, fixed atten)
{
	fixed4 Ci;
	
	float3 lamHairDiff = lambertHair(lightDir, s.Normal);
	
	// This adds the waviness to the spec highlight based on a noisy texture, also can shift the highlight across the surface
	float specNoise = _SpecShift;
	specNoise = (((s.SpecNoise * 2) - 1) * _SpecNoiseScale) + _SpecShift;
	
	// Smoothstep allows us to harden or soften the edge of the primary spec highlight
	float3 spec1 = _SpecOpac * smoothstep(0.72 - _SpecSharp, 0.72 + _SpecSharp, pow(kajiyaKay(s.NormalBasic, s.Bw, viewDir, lightDir, specNoise), _SpecPower));  
	// A secondary specular highlight shifted slightly above and tinted with the diffuse textrue color and the hair color
	float3 spec2 = pow(kajiyaKay(s.Normal, s.Bw, viewDir, lightDir, specNoise + 0.15), _SpecPower / 4) * s.Albedo * _Color;
	
	float3 specCombo = (spec1 + spec2) * _SpecTint;
	
	Ci.rgb = ((s.Albedo + specCombo) * _LightColor0.rgb * lamHairDiff + _LightColor0.rgb * specCombo) * (atten * 2);
	Ci.a = s.Alpha + _LightColor0.a * _SpecColor.a * specCombo * atten;
	return Ci;
}
		
		
////////////////////////////////////////
//     Eyeball Lighting           	  //
////////////////////////////////////////

// Fresnel Term
float fresnel(float3 norm, float3 eyevec, float falloff)
{
	norm = normalize(norm);
	eyevec = normalize(eyevec);

	float fresnelTerm = saturate(abs(dot(norm, eyevec)));											// Get fresnel term by dot product between normal and eye
	fresnelTerm = pow(fresnelTerm, falloff);														// Strengthen to power of user-defined falloff

	return saturate(fresnelTerm);
}

// Function to overlay textures using an alpha channel)
float4 OverlayTextures(float3 color0, float3 color1, float maskColor)
{
	float4 finalColor = float4(color0, maskColor);
    finalColor.rgb = lerp(finalColor.rgb, color1, maskColor);
    return finalColor;
}

// Calculate binormal as described in UnityCG.cginc
float3 BinormalCalc(appdata_full v)
{
	return cross(v.normal, v.tangent.xyz) * v.tangent.w;
}

// Lighting properties
float _ReflStr;
float4 _Ambient;
float _SMStr;
float4 _CSpecColor;
float4 _ISpecColor;
float _CSpecStr;
float _ISpecStr;

// Lighting structs
struct SurfaceOutputRE
{
	fixed3 Albedo;
	fixed3 Normal;
	fixed3 Emission;
	half Specular;
	fixed3 Gloss;
	fixed Alpha;
	half3 Refl;
	half3 ReflAmt;
	half Shadow;
};

// This is the lighting model for the eyeball
inline fixed4 LightingReflectiveEye(SurfaceOutputRE s, fixed3 lightDir, half3 viewDir, fixed atten)
{
	fixed4 c;
	// Diffuse term
	fixed diff = max(0, dot(s.Normal, lightDir));													// Compute diffuse lighting
	diff = lerp(diff, (diff - s.Shadow), _SMStr);													// Apply shadow based on strength
	float3 bakedShadow = float3(s.Shadow, s.Shadow, s.Shadow);
	
	// Calculate specular term
	float4 totalspecular = (0.0, 0.0, 0.0, 0.0);
	half3 H = normalize(lightDir + viewDir);
	float NdotH = max(0, dot(s.Normal, H));

	float SpecPower = pow(NdotH, s.Gloss);
	float3 specStrength = OverlayTextures(_CSpecStr - 1, _ISpecStr - 1, s.Alpha);     				// Combine cornea and iris spec levels, subtract from cornea level to account for alpha
	float4 specColor = OverlayTextures(_CSpecColor, _ISpecColor, s.Alpha);          				// Combine cornea and iris spec colors

	specStrength -= bakedShadow - _SMStr;															// Remove some spec from AO shadows
	SpecPower *= _LightColor0.rgb * specStrength;                                                   // Multiply by light color * specular strength
	totalspecular = SpecPower * specColor;                                                    		// Multiply in specular color

	c.rgb = ((s.Albedo + s.Refl) * _LightColor0.rgb * diff + _LightColor0.rgb * totalspecular.rgb) * (atten * 2);
	c.a = s.Alpha + _LightColor0.a * _SpecColor.a * atten;
	return c;	
}


#endif