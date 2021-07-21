Shader "Custom/InstancedIndirectColor" {
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
    }
    
    SubShader {
        Tags { "RenderType" = "Opaque" }

        Cull Back
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        Lighting Off

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            //This comes from GrabPass shader and material to get this once
            sampler2D _MainTex;
            sampler2D _TerrainGrab;
            float4 _MainTex_ST;

            struct appdata_t {
                float4 vertex   : POSITION;
                float2 uv : TEXCOORD0;
                float4 color    : COLOR;
            };

            struct v2f {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 uv : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
            }; 

            struct MeshProperties {
                float4x4 mat;
                float4 color;
            };

            StructuredBuffer<MeshProperties> _Properties;

            v2f vert(appdata_t i, uint instanceID: SV_InstanceID) {
                v2f o;

                float4x4 mat = _Properties[instanceID].mat;

                float4 pos = mul(mat, i.vertex);
                o.vertex = UnityObjectToClipPos(pos);
                o.color = _Properties[instanceID].color;

                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                
                float3 position = float3(mat[0][3], mat[1][3], mat[2][3]);

                // float4 positionBottomMiddle = UnityObjectToClipPos(float4(0,-0.5,0,1));
                float4 positionBottomMiddle = UnityObjectToClipPos(position-0.5);
                o.screenPos = ComputeScreenPos(positionBottomMiddle);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                float2 uv = i.screenPos.xy / i.screenPos.w;
                float4 bgcolor = tex2D(_TerrainGrab, uv);
                bgcolor.a = bgcolor.a * tex2D(_MainTex, i.uv).a;

                return bgcolor;
                // return i.color;

            }

            ENDCG
        }
    }
}