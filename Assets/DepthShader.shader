Shader "Postprocessing/depthShader"{
    //show values to edit in inspector
    
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
        _Offset ("Pixel Offset", Range (0,20)) = 0.001
        _Power ("Sobel Power", Range(0,20)) = 1
        [Header(Outside Edge Detection)] [Space]
        _Threshold ("First Clamp", Range(0,2)) = 0.1
        _Threshold2 ("Slope of Tanh", Range(0,4)) = 1
        _Threshold3 ("Clamp of Tanh", Range(0,8)) = 2
        _Threshold4 ("Last Clamp", Range(0,1)) = 0.2
        [Header(Inside Edge Detection)] [Space]
        _Threshold5 ("First Clamp", Range(0,2)) = 0.1
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
            #define PI 3.14159265358979323846

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

            float _PixelDensity;

            float _Power;

            float _Threshold;
            float _Threshold2;
            float _Threshold3;
            float _Threshold4;
            float _Threshold5;

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

                // baseNormal = baseNormal * 0.5 + 0.5;


                // float neighborDepth = baseDepth - (baseNormal.x*positionOffset.x + baseNormal.y*positionOffset.y)*_Offset;

                float neighborDepth = baseDepth + baseNormal.x*positionOffset.x*_Offset + baseNormal.y*positionOffset.y*_Offset;
                
                
                neighbor.depth = neighborDepth;

                return neighbor;
                // float depth = baseDepth + 
            }

            float getDepth (float2 uv, float2 offset){
                float4 depthNormal = tex2D(_CameraDepthNormalsTexture, 
                        uv + _CameraDepthNormalsTexture_TexelSize.xy * offset);
                float3 normal;
                float depth;
                DecodeDepthNormal(depthNormal, depth, normal);
                return depth = depth * _ProjectionParams.z;
            }

            float2 sobel (float2 uv){
                float up = getDepth(uv, float2(0.0, 1.0));  
                float down = getDepth(uv, float2(0.0, -1.0));
                float left = getDepth(uv, float2(1.0, 0.0));
                float right = getDepth(uv, float2(-1.0, 0.0));
                float centre = getDepth(uv, float2(0,0));

                float depth = max(max(up, down), max(left, right));
                return float2(clamp(up - centre, 0, 1) + clamp(down - centre, 0, 1) + clamp(left - centre, 0, 1) + clamp(right - centre, 0, 1), depth);
            }

            float outerEdgeDetect (float depthDifference){
                float result = depthDifference;
                result = clamp(result-_Threshold, 0, 1-_Threshold)*(1/(1-_Threshold));
                result = (tanh(2*PI*result*_Threshold2 - _Threshold3) + 1);
                // result = pow()
                
                return result;
            }

            float innerEdgeDetect (pixel basePixel, pixel newPixel){
                float3 baseNormal = basePixel.normal;
                float3 newNormal = newPixel.normal;

                float3 magBaseNormal = baseNormal-newNormal;
                float result = magBaseNormal.x + magBaseNormal.y + magBaseNormal.z;

                result = step(0.00001, result);
                // result = clamp(result,0,1);
                

                

                // float result = 1-dot(baseNormal,newNormal)/abs(baseNormal)*abs(newNormal);
                // result = abs(result);

                // float3 result = basePixel.normal - newPixel.normal;
                // result = result.x + result.y + result.z;
                // result = abs(result);

                [branch] if(abs(basePixel.depth - newPixel.depth)>0.25){
                    result = 0;
                }

                // result = outerEdgeDetect(result);

                // float result = 
                // result = tanh(result);
                // result = pow(result, 0.01);
                result = clamp(result, 0, 1-_Threshold5);


                return result;
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

                // float depthDifference = 
                //             up.depth - predictedUp.depth + 
                //             down.depth - predictedDown.depth + 
                //             left.depth - predictedLeft.depth + 
                //             right.depth - predictedRight.depth;
                            
                float outerEdge = 
                            outerEdgeDetect(up.depth - predictedUp.depth)
                            + outerEdgeDetect(down.depth - predictedDown.depth)
                            + outerEdgeDetect(left.depth - predictedLeft.depth)
                            + outerEdgeDetect(right.depth - predictedRight.depth);

                float innerEdge = 
                            innerEdgeDetect(up, predictedUp)
                            + innerEdgeDetect(down, predictedDown)
                            + innerEdgeDetect(left, predictedLeft)
                            + innerEdgeDetect(right, predictedRight);
                            
                // depthDifference = edgeDetect(up.depth - predictedUp.depth)+ edgeDetect(left.depth - predictedLeft.depth);
                // float depthDifference = 
                //             predictedUp.depth - up.depth + predictedLeft.depth - left.depth;

                // float depthDifference = depth - up.depth + depth - down.depth + depth - left.depth + depth - right.depth;

                // depthDifference = 0.25*depthDifference;

                // depthDifference = clamp(depthDifference,-1,0);

                // depthDifference = sqrt(depthDifference*depthDifference);
                // depthDifference = depthDifference*0.01;

                // depthDifference = pow(depthDifference, 9);
                // depthDifference = step(0.3, depthDifference);
                // depthDifference = pow(depthDifference, 2);

                // depthDifference = pow(depthDifference,1);
                // diff = step(0.9, diff);

                outerEdge = clamp(outerEdge-_Threshold4,0,1-_Threshold4)*(1/(1-_Threshold4));


                // depthDifference = step(0.25, depthDifference);

                fixed4 col = tex2D(_MainTex, i.uv);
                // diff = pow(diff, 6);
                // diff = diff*0.1;
                // depthDifference = clamp(depthDifference, 0, 1);

                // depthDifference = pow(depthDifference,0.5);

                // diff = pow(diff, _Power);
                // diff = step(_Cutoff, diff);

                // float4 scaledNormal = float4( float3( 1 - ( normal.xyz + 1 ) / 2 ), 1 );

                // float scaledNormal = normal.x;

                // scaledNormal = sqrt(scaledNormal*scaledNormal);


                col = lerp(col, float4(1,0,1,1), outerEdge);
                col = lerp(col, float4(0,1,0,1), innerEdge);

                // col = pow(col, 2);

                // float pos = DecodeFloatRGBA(float4(normal,1));

                // float4 position = pow(i.position, 99999);

                // float predictedDepth = predictedRight.depth + predictedUp.depth + predictedLeft.depth + predictedDown.depth;

                // return float4(0,i.position.y*0.005,0,1);
                // return float4(abs(predictedUp.depth)*0.25*0.03,0,0,1);
                // return float4(normal.z*0.5+0.5,0,0,1);
                return col;

                // //----- SOBEL FILTER -------
                // float2 sobelData = sobel(i.uv);
                // float s = pow(abs(1 - saturate(sobelData.x)), _Power);
                // s = floor(s+0.2);
                // s = lerp(1.0, s, ceil(sobelData.y - depth));
                // // float sobelDepth = lerp(sobelData.y, SampleDepth(input.uv), s);
                // col.rgb *= s;
                // col.a += 1 - s;
                // return col;
                // //---------------------------

            }

            ENDCG
        }
    }
}