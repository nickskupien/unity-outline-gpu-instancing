// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/GrassShader" {
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        // Draw after all opaque geometry
        Tags { "Queue" = "Transparent" }

        // Grab the screen behind the object into _BackgroundTexture
        GrabPass
        {
            "_BackgroundTexture"
        }

        // Render the object with the texture generated above, and invert the colors
        Pass
        {
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members worldPos,objectPos)
            #pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;

            //the object data that's put into the vertex shader
            struct appdata{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            //the data that's used to generate fragments and can be read by the fragment shader
            struct v2f{
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1;
                float4 objPos : TEXCOORD2;
            };

            //using this to hold pixel data
            struct pixel{
                float depth;
                float3 normal;
            };

            //the vertex shader
            v2f vert(appdata v){
                v2f o;
                //convert the vertex positions from object space to clip space so they can be rendered
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                // use ComputeGrabScreenPos function from UnityCG.cginc
                // to get the correct texture coordinate
                o.grabPos = ComputeGrabScreenPos(o.position);

                // o.objPos = mul(unity_ObjectToWorld, v.vertex);
                // o.objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));

                o.objPos = mul(unity_ObjectToWorld, v.vertex);
                // o.objPos = mul(unity_WorldToObject, o.objPos);

                return o;
                
            }

            sampler2D _BackgroundTexture;

            half4 frag(v2f i) : SV_Target
            {

                // half4 bgcolor = tex2Dproj(_BackgroundTexture, float4(i.grabPos.x,i.grabPos.y,i.grabPos.z,i.grabPos.a));
                float4 bgcolor = tex2D(_BackgroundTexture, i.objPos);
                return bgcolor;
                
            }
            ENDCG
        }

    }
}