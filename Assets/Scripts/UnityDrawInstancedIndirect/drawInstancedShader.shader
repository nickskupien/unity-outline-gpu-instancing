Shader "Custom/InstancedIndirectColor" {
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
        _FlickerOffset("Offset for adjusting flicker", Range(0,5)) = 0.01
        _GrassRandomness("Adjusting random colour variations", Range(0,1)) = 0.5
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
                fixed4 random    : COLOR0;
                fixed4 colour : COLOR1; 
                float textureid : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            }; 

            struct MeshProperties {
                float4x4 mat;
                float textureid; 
                float4 colour;
            };

            StructuredBuffer<MeshProperties> _Properties;
            float _FlickerOffset;

            float4 getGrassColour(float3 position){
                float4 middlePos = UnityObjectToClipPos(float3(position.x,position.y-1,position.z));
                float4 leftPos = UnityObjectToClipPos(float3(position.x-_FlickerOffset,position.y-1,position.z));
                float4 rightPos = UnityObjectToClipPos(float3(position.x+_FlickerOffset,position.y-1,position.z));
                float4 upPos = UnityObjectToClipPos(float3(position.x,position.y-1,position.z+_FlickerOffset));
                float4 downPos = UnityObjectToClipPos(float3(position.x,position.y-1,position.z-_FlickerOffset));
                float4 diagPos1 = UnityObjectToClipPos(float3(position.x-_FlickerOffset,position.y-1,position.z-_FlickerOffset));
                float4 diagPos2 = UnityObjectToClipPos(float3(position.x-_FlickerOffset,position.y-1,position.z+_FlickerOffset));
                float4 diagPos3 = UnityObjectToClipPos(float3(position.x+_FlickerOffset,position.y-1,position.z-_FlickerOffset));
                float4 diagPos4 = UnityObjectToClipPos(float3(position.x+_FlickerOffset,position.y-1,position.z+_FlickerOffset));

                middlePos = ComputeScreenPos(middlePos);
                leftPos = ComputeScreenPos(leftPos);
                rightPos = ComputeScreenPos(rightPos);
                upPos = ComputeScreenPos(upPos);
                downPos = ComputeScreenPos(downPos);
                diagPos1 = ComputeScreenPos(diagPos1);
                diagPos2 = ComputeScreenPos(diagPos2);
                diagPos3 = ComputeScreenPos(diagPos3);
                diagPos4 = ComputeScreenPos(diagPos4);

                float4 middle = tex2Dlod(_TerrainGrab, middlePos);
                float4 left = tex2Dlod(_TerrainGrab, leftPos);
                float4 right = tex2Dlod(_TerrainGrab, rightPos);
                float4 up = tex2Dlod(_TerrainGrab, upPos);
                float4 down = tex2Dlod(_TerrainGrab, downPos);
                float4 diag1 = tex2Dlod(_TerrainGrab, diagPos1);
                float4 diag2 = tex2Dlod(_TerrainGrab, diagPos2);
                float4 diag3 = tex2Dlod(_TerrainGrab, diagPos3);
                float4 diag4 = tex2Dlod(_TerrainGrab, diagPos4);

                float4 minimum = min(min(min(min(left, right), min(up, down)), min(min(diag1, diag2), min(diag3, diag4))), middle);
                float4 maximum = max(max(max(max(left, right), max(up, down)), max(max(diag1, diag2), max(diag3, diag4))), middle);

                float4 average = (middle + left + right + up + down + diag1 + diag2 + diag3 + diag4)/9;

                float4 minimumDifference = average - minimum;
                float4 maximumDifference = maximum - average; 

                float4 mode = (minimumDifference <= maximumDifference) ? minimum : maximum;

                return mode;
            }

            v2f vert(appdata_t i, uint instanceID: SV_InstanceID) {
                v2f o;

                float4x4 mat = _Properties[instanceID].mat;

                float4 pos = mul(mat, i.vertex);
                o.vertex = UnityObjectToClipPos(pos); 
                o.random = _Properties[instanceID].colour;
                o.textureid = _Properties[instanceID].textureid;

                o.uv = TRANSFORM_TEX(i.uv, _MainTex);
                
                float3 position = float3(mat[0][3], mat[1][3], mat[2][3]);

                float4 positionBottomMiddle = UnityObjectToClipPos(float4(0,-0.5,0,1));
            
                o.screenPos = ComputeScreenPos(positionBottomMiddle);
                o.colour = getGrassColour(position);

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
            float _GrassRandomness;

            float4 checkNeighborColours(float2 uv){
                float4 left = tex2D(_TerrainGrab, uv - float2(_FlickerOffset,0));
                float4 right = tex2D(_TerrainGrab, uv - float2(-_FlickerOffset,0));
                float4 up = tex2D(_TerrainGrab, uv - float2(0,_FlickerOffset));
                float4 down = tex2D(_TerrainGrab, uv - float2(0,-_FlickerOffset));
                return min(max(left,right), max(up,down));
            }

            fixed4 frag(v2f i) : SV_Target {
 
                float2 uvTexture = getTextureUnpacked(i.uv, i.textureid);

                float4 bgcolor = i.colour;
                bgcolor.xyz = bgcolor.xyz * (1-i.textureid*_GrassRandomness);

                float textureAlpha = bgcolor.a * tex2D(_MainTex, uvTexture).a;

                clip(textureAlpha - _Cutoff);
 
                // bgcolor.a = textureAlpha*0.8;

                // return i.screenPos;
                return bgcolor;
                // return i.color;

            }

            ENDCG
        }
    }
}