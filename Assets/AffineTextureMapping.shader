Shader "Custom/AdvancedAffineTextureMappingWithVertexSnappingPlusEffects"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WarpIntensity ("Warp Intensity", Float) = 1.0
        _JitterIntensity ("Jitter Intensity", Float) = 0.01
        _GridSize("Grid Size", Float) = 0.25 // Vertex snapping grid size
        _PaletteSize("Palette Size", Float) = 16.0 // For limited color palette
        _PixelationSize("Pixelation Size", Float) = 128.0 // For pixelation effect
        // Lighting properties
        _LightColor ("Light Color", Color) = (1,1,1,1)
        _AmbientLight ("Ambient Light", Color) = (0.5,0.5,0.5,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members lightIntensity)
#pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float lightIntensity : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _WarpIntensity;
            float _JitterIntensity;
            float _GridSize; // For vertex snapping
            float _PaletteSize; // For limited color palette
            float _PixelationSize; // For pixelation effect
            // Lighting properties
            float4 _LightColor;
            float4 _AmbientLight;

            v2f vert (appdata v)
            {
                v2f o;

                // Vertex Snapping Logic
                float3 gridPosition = v.vertex.xyz / _GridSize;
                gridPosition = round(gridPosition);
                gridPosition *= _GridSize;
                v.vertex.xyz = gridPosition;

                o.vertex = UnityObjectToClipPos(v.vertex);


                // Integrate time-dependent jitter
                float time = _Time.y * 60.0;
                float2 jitterValue = _JitterIntensity * (float2(sin(v.vertex.x * 1.0 + time), cos(v.vertex.y * 1.0 + time)) - 0.5);
                o.vertex.xy += jitterValue;

                // Apply affine mapping with optional warping intensity
                o.uv = v.uv * _WarpIntensity;

                // Simple vertex lighting calculation
                float3 norm = normalize(v.normal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz)*-1;
                float diff = max(dot(norm, lightDir), 0);
                // Quantize light intensity
                const float steps = 4.0; // Adjust for more/less quantization
                o.lightIntensity = floor(diff * steps) / steps;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Pixelation effect
                float2 pixelSize = 1.0 / _PixelationSize;
                i.uv = floor(i.uv / pixelSize) * pixelSize;

                // Sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                // Limited Color Palette
                col.rgb = floor(col.rgb * _PaletteSize) / _PaletteSize;

                // Apply quantized lighting
                col *= i.lightIntensity * _LightColor + _AmbientLight;

                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
