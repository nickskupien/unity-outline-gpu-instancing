Shader "Postprocessing/depthShader"{
    //show values to edit in inspector
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
        _Offset ("Pixel Offset", Range (0,1)) = 0.001
    }

    SubShader{
        // markers that specify that we don't need culling
        // or reading/writing to the depth buffer
        // Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        ZTest Always

        Pass{
            CGPROGRAM
            //include useful shader functions
            #include "UnityCG.cginc"

            //define vertex and fragment shader
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;

            //texture and transforms of the texture
            // sampler2D _CameraDepthTexture;
            sampler2D _CameraDepthNormalsTexture;
            //texelsize of the depthnormals texture
            float4 _CameraDepthNormalsTexture_TexelSize;

            float _Offset;

            //matrix to convert from view space to world space
            float4x4 _viewToWorld;

            //the object data that's put into the vertex shader
            struct appdata{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            //the data that's used to generate fragments and can be read by the fragment shader
            struct v2f{
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
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
                return o;
            }

            pixel GetNeighbor(float2 uv, float2 offset){
                //read neighbor pixel
                float4 neighborDepthnormal = tex2D(_CameraDepthNormalsTexture, 
                        uv + _CameraDepthNormalsTexture_TexelSize.xy * offset);
                float3 neighborNormal;
                float neighborDepth;
                DecodeDepthNormal(neighborDepthnormal, neighborDepth, neighborNormal);
                neighborDepth = neighborDepth * _ProjectionParams.z;

                neighborNormal = mul((float3x3)_viewToWorld, neighborNormal);

                // float3 normalDifference = baseNormal-neighborNormal;
                // normalDifference = normalDifference.r + normalDifference.g + normalDifference.b;

                // depthDifference = depthDifference

                pixel neighbor;
                neighbor.depth = neighborDepth;
                neighbor.normal = neighborNormal;

                return neighbor;
            }

            pixel PredictNeighbor(float baseDepth, float3 baseNormal, float3 position, float2 positionOffset){
                pixel neighbor;
                neighbor.normal = baseNormal;


                float neighborDepth = baseDepth - (baseNormal.x*positionOffset.x + baseNormal.y*positionOffset.y)*_Offset;
                
                
                neighbor.depth = neighborDepth;

                return neighbor;
                // float depth = baseDepth + 
            }

            //the fragment shader
            fixed4 frag(v2f i) : SV_TARGET{
                //read depthnormal
                float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);

                //decode depthnormal
                float3 normal;
                float depth;
                DecodeDepthNormal(depthnormal, depth, normal);

                normal = mul((float3x3)_viewToWorld, normal);

                //get depth as distance from camera in units 
                depth = depth * _ProjectionParams.z;

                pixel up = GetNeighbor(i.uv, float2(0, 1));
                pixel down = GetNeighbor(i.uv, float2(0, -1));
                pixel left = GetNeighbor(i.uv, float2(-1, 0));
                pixel right = GetNeighbor(i.uv, float2(1, 0));

                pixel predictedUp = PredictNeighbor(depth, normal, i.position, float2(0, -1));
                pixel predictedDown = PredictNeighbor(depth, normal, i.position, float2(0, 1));
                pixel predictedLeft = PredictNeighbor(depth, normal, i.position, float2(-1, 0));
                pixel predictedRight = PredictNeighbor(depth, normal, i.position, float2(1, 0));

                float depthDifference = 
                            predictedUp.depth - up.depth + 
                            predictedDown.depth - down.depth + 
                            predictedLeft.depth - left.depth + 
                            predictedRight.depth - right.depth;
                            

                // float depthDifference = 
                //             predictedUp.depth - up.depth + predictedLeft.depth - left.depth;

                // float depthDifference = depth - up.depth + depth - down.depth + depth - left.depth + depth - right.depth;

                // depthDifference = sqrt(depthDifference*depthDifference);

                // depthDifference = pow(depthDifference, 9);
                // depthDifference = step(0.3, depthDifference);
                // depthDifference = pow(depthDifference, 2);

                // depthDifference = pow(depthDifference,1);
                // diff = step(0.9, diff);

                depthDifference = clamp(depthDifference-0.1,0,1);

                depthDifference = step(0.3, depthDifference);

                fixed4 col = tex2D(_MainTex, i.uv);
                // diff = pow(diff, 6);
                // diff = diff*0.1;
                depthDifference = clamp(depthDifference, 0, 1);

                // depthDifference = pow(depthDifference,0.5);

                // diff = pow(diff, _Power);
                // diff = step(_Cutoff, diff);

                // float4 scaledNormal = float4( float3( 1 - ( normal.xyz + 1 ) / 2 ), 1 );

                float scaledNormal = normal.x;

                scaledNormal = sqrt(scaledNormal*scaledNormal);


                col = lerp(col, float4(1,0,1,1), depthDifference);

                // col = pow(col, 2);

                // float pos = DecodeFloatRGBA(float4(normal,1));

                // float4 position = pow(i.position, 99999);

                // float predictedDepth = predictedRight.depth + predictedUp.depth + predictedLeft.depth + predictedDown.depth;

                // return float4(0,i.position.y*0.005,0,1);
                // return float4(predictedLeft.depth*0.25*0.03,0,0,1);
                // return float4(scaledNormal,0,0,1);
                return col;
            }

            ENDCG
        }
    }
}