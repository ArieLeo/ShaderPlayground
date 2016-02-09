Shader "Advanced SS/Bump/Diffuse"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Bumpmap", 2D) = "bump" {}
    }

    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType"="Opaque"}
        LOD 500

        CGPROGRAM

        #define ADVANCEDSS_BUMP

        #pragma target 3.0
        #include "../AdvancedSS.cginc"
        #pragma surface advancedSurfaceShader Lambert

        ENDCG
    }

    Fallback "Diffuse"
}