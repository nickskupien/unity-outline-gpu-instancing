Shader "Custom/GrabPassTrick"
{
    Properties
    {}

    SubShader
    {
        Tags { "Queue" = "Transparent" }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        GrabPass
        {
            "_TerrainGrab" // replace this with any suitable name, don't forget to use it other related shaders
        }

        Pass
        {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 vert(void) : SV_POSITION
            {
                return (0.0).xxxx;
            }

            float4 frag(void) : COLOR
            {
                return (0.0).xxxx;
            }
        ENDCG
        }
    }
}