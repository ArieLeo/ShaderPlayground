Shader "Hair/ATIHairSketchFull" 
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
        _SpecOpac ("Specular opacity", Range(0.0, 1.0)) = 0.5
        _SpecScale ("Specular fresnel multiplier", Range(1.0, 15.0)) = 1.0
		_CubeMap ("Cubemap reflection", CUBE) = "" {}
		_ReflOpac ("Reflection opacity", Range(0.0, 1.0)) = 0.05
		_RimPower("Rim Power", Range(0.01, 4.0)) = 1.5
        _RimOpacity("Rim opacity", Range(0.0, 1.0)) = 1.0
	}
	
	SubShader 
	{		
		LOD 300
		
		UsePass "Hair/ATIHairSketchPass1/FORWARD"
		UsePass "Hair/ATIHairSketchPass2/FORWARD"
		UsePass "Hair/ATIHairSketchPass3/FORWARD"
		UsePass "Hair/ATIHairSketchPass4/FORWARD"
	}
	
	FallBack "Transparent/Cutout/Specular"
}