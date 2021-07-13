Shader "Custom/GrassShader" {
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        // Draw after all opaque geometry
        Tags { "Queue" = "Transparent" }

        // Grab the screen behind the object into _BackgroundTexture
        // GrabPass
        // {
        //     "_BackgroundTexture"
        // }

        Blend SrcAlpha OneMinusSrcAlpha
        Lighting Off
        ZWrite Off
        Cull Off

        // Render the object with the texture generated above, and invert the colors
        Pass
        {
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members worldPos,objectPos)
            #pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            //This comes from GrabPass shader and material to get this once
            sampler2D _TerrainGrab;
            sampler2D _BackgroundTexture;
            float4 _MainTex_ST;


            //the object data that's put into the vertex shader
            struct appdata{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            //the data that's used to generate fragments and can be read by the fragment shader
            struct v2f{
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertex : TEXCOORD3;
                float4 screenPos : TEXCOORD1;
                float4 objPos : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            //using this to hold pixel data
            struct pixel{
                float depth;
                float3 normal;
            };

            //the vertex shader
            v2f vert(appdata v){
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                //convert the vertex positions from object space to clip space so they can be rendered
                o.vertex = v.vertex;
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // o.uv = v.uv;

                // o.position = UnityObjectToClipPos(v.vertex);
                float4 positionBottomMiddle = UnityObjectToClipPos(float4(0,-0.5,0,1));
                // positionBottomMiddle = UnityObjectToClipPos(v.vertex);

                // use ComputeGrabScreenPos function from UnityCG.cginc
                // to get the correct texture coordinate
                o.screenPos = ComputeScreenPos(positionBottomMiddle);
                // o.screenPos = positionBottomMiddle;

                // o.objPos = mul(unity_ObjectToWorld, v.vertex);
                // o.objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));

                o.objPos = v.vertex;
                o.objPos = mul(unity_WorldToObject, o.objPos);

                // float3 worldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)).xyz;
                // float3 playerToVertexVec = worldPos - _PlayerPos.xyz;
                // float3 playerToVertexDir = normalize(playerToVertexVec);
                // float playerToVertexDist = length(playerToVertexVec);
                // worldPos += playerToVertexDir * (1 - saturate(playerToVertexDist / _BendRange)) * _BendStrength;
                // o.objPos = float4(worldPos, 1);

                return o;
                
            }

            // sampler2D _BackgroundTexture;

            float4 frag(v2f i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                // half4 bgcolor = tex2Dproj(_TerrainGrab, float4(i.grabPos.x,i.grabPos.y,i.grabPos.z,i.grabPos.a));
                // Linear01
                float2 uv = i.screenPos.xy / i.screenPos.w;
                // uv = trunc(uv);

                float4 bgcolor = tex2D(_TerrainGrab, uv);
                // bgcolor = tex2D(_BackgroundTexture, uv);
                bgcolor.a = bgcolor.a * tex2D(_MainTex, i.uv).a;
                // return float4(uv,0,1);
                // return float4(i.vertex.xyz,1);
                // return float4(i.position.rgb*0.01,1);
                // return i.screenPos;
                // return float4()
                // return unity_InstanceID;
                return bgcolor;
                
            }
            ENDCG
        }

    }
}