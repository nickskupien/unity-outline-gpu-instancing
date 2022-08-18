Shader "Postprocessing/outlineShader"{
    //show values to edit in inspector
    
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
        // _Type ("Sobel", Bool) = 1
        _FogColour ("Fog Colour", Color) = (1,1,1,1)
        _Offset ("Pixel Offset", Range (0,1)) = 0.001
        _Power ("Sobel Power", Range(0,20)) = 1
        _SobelFloor ("Sobel Floor", Range(0,1)) = 0.1
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

            float _FogColour;

            float _PixelDensity;

            float _Power;

            float _SobelFloor;

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
                        uv + _CameraDepthNormalsTexture_TexelSize.xy * offset * _Offset);
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
                        uv + _CameraDepthNormalsTexture_TexelSize.xy * offset * _Offset);
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

                float result;

                float magBaseNormal = length(baseNormal);
                float magNewNormal = length(newNormal);

                // float3 magBaseNormal = baseNormal-newNormal;
                // float result = magBaseNormal.x + magBaseNormal.y + magBaseNormal.z;

                // result = step(0.00001, result);
                // // result = clamp(result,0,1);



                // float3 crossProduct = cross(baseNormal, newNormal);
                // float magCrossProduct = length(crossProduct);
                // float angleBetweenNormals = sign(crossProduct.y)*magCrossProduct/(magBaseNormal*magNewNormal);
                // // result = -clamp(angleBetweenNormals,-1,0);
                // result = crossProduct.y;
                // result = step(0.2,result);
                

                float3 diffNormal = baseNormal-newNormal;
                result = diffNormal.x + diffNormal.y + diffNormal.z;

                result = step(0.01, result);
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
                // result = clamp(result, 0, 1-_Threshold5);


                return result;
            }

            //the fragment shader
            fixed4 frag(v2f i) : SV_TARGET{

                // 1 = sobel, 2 = legacy
                int type = 1;

                //read depthnormal
                float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);
                fixed4 baseCol = tex2D(_MainTex, i.uv);

                //decode depthnormal
                float3 normal;
                float depth;
                DecodeDepthNormal(depthnormal, depth, normal);

                normal = mul((float3x3)_viewToWorld, normal);

                //get depth as distance from camera in units 

                // depth = Linear01Depth(depth);
                depth = depth * _ProjectionParams.z;


                depth = depth*_Threshold2;

                depth = pow(depth,_Threshold3);

                //get depth as distance from camera in units 

                // return float4(normal,1);

                // up = step(0.5, up);
                return lerp(baseCol, float4(1,0.9,0.9,1), depth);

            }

            ENDCG
        }
    }
}