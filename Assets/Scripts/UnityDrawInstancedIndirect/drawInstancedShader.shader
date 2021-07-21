Shader "Custom/InstancedIndirectColor" {
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    
    SubShader {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }

        // Cull Back
        ZWrite On
        // ZTest LEqual
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
                float textureid : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            }; 

            struct MeshProperties {
                float4x4 mat;
                float textureid; 
                float4 color;
            };

            StructuredBuffer<MeshProperties> _Properties;

            v2f vert(appdata_t i, uint instanceID: SV_InstanceID) {
                v2f o;

                float4x4 mat = _Properties[instanceID].mat;

                float4 pos = mul(mat, i.vertex);
                o.vertex = UnityObjectToClipPos(pos); 
                o.color = _Properties[instanceID].color;
                o.textureid = _Properties[instanceID].textureid;

                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                
                float3 position = float3(mat[0][3], mat[1][3], mat[2][3]);

                // float4 positionBottomMiddle = UnityObjectToClipPos(float4(0,-0.5,0,1));
                float4 positionBottomMiddle = UnityObjectToClipPos(position-0.5);
                o.screenPos = ComputeScreenPos(positionBottomMiddle);

                return o;
            }

            float2 getTextureUnpacked(float2 uv, float i){
                float2 index = float2(floor(i/2), floor(i/4));
                float2 uvOutput = uv;
                float2 texturePacking = float2(0.25, 0.5);
                float2 bounds = float2(0.01,0.01);
                float2 offset = index * texturePacking;
                uvOutput = uvOutput * texturePacking;
                uvOutput = uvOutput + offset;
                uvOutput = clamp(uvOutput, offset + bounds, offset + texturePacking - bounds);
                // uvOutput = uv;
                return uvOutput;
            }

            float _Cutoff;

            fixed4 frag(v2f i) : SV_Target {
 
                float2 uvTexture = getTextureUnpacked(i.uv, i.textureid);

                float2 uv = i.screenPos.xy / i.screenPos.w;
                float4 bgcolor = tex2D(_TerrainGrab, uv);
                // bgcolor = float4(i.textureid/8,1,0,1);

                float textureAlpha = bgcolor.a * tex2D(_MainTex, uvTexture).a;

                clip(textureAlpha - _Cutoff);
 
                bgcolor.a = textureAlpha;

                return bgcolor;
                // return i.color;

            }

            ENDCG
        }
    }
}