Shader "Postprocessing/depthShader1"{
    //show values to edit in inspector
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
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

            //the vertex shader
            v2f vert(appdata v){
                v2f o;
                //convert the vertex positions from object space to clip space so they can be rendered
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float Compare(float baseDepth, float baseNormal, float2 uv, float2 offset){
                //read neighbor pixel
                float4 neighborDepthnormal = tex2D(_CameraDepthNormalsTexture, 
                        uv + _CameraDepthNormalsTexture_TexelSize.xy * offset);
                float3 neighborNormal;
                float neighborDepth;
                // float predictedPixel = 
                DecodeDepthNormal(neighborDepthnormal, neighborDepth, neighborNormal);
                neighborDepth = neighborDepth * _ProjectionParams.z;

                neighborNormal = mul((float3x3)_viewToWorld, neighborNormal);

                float3 normalDifference = baseNormal-neighborNormal;

                return normalDifference;
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

                float depthDifference = Compare(depth, normal, i.uv, float2(1, 0));
                depthDifference = depthDifference + Compare(depth, normal, i.uv, float2(0, 1));
                depthDifference = depthDifference + Compare(depth, normal, i.uv, float2(0, -1));
                depthDifference = depthDifference + Compare(depth, normal, i.uv, float2(-1, 0));

                // depthDifference = pow(depthDifference, 6);
                depthDifference = step(0.7, depthDifference);
                // depthDifference = pow(depthDifference, 2);

                fixed4 col = tex2D(_MainTex, i.uv);



                col = lerp(col, float4(1,0,1,1), depthDifference);

                // col = pow(col, 2);

                return col;
                
            }

            ENDCG
        }
    }
}