Shader "Custom/Gerstner Wave"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _DirectionAB("WaveA and B direction", Vector) = (1,0,0.5,10)
        _DirectionCD("WaveC and D direction", Vector) = (1,0,0.5,10)
        _WaveA ("Wave A (x = speed,y = amplitude,z = steepness,w = wavelength)", Vector) = (1,0,0.5,10)
        _WaveB ("Wave B (x = speed,y = amplitude,z = steepness,w = wavelength)", Vector) = (1,0,0.5,10)
        _WaveC ("Wave C (x = speed,y = amplitude,z = steepness,w = wavelength)", Vector) = (1,0,0.5,10)
        //_WaveD ("Wave D (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
        //_WaveE ("Wave E (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
        //_WaveF ("Wave F (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
        //_WaveG ("Wave G (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
        //_WaveH ("Wave H (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
    
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tess addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 4.6
        #include "Tessellation.cginc"
        
        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 color :COLOR;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float4 _WaveA, _WaveB, _WaveC, _WaveD, _WaveE, _WaveF, _WaveG, _WaveH, _DirectionAB, _DirectionCD;
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float4 tess (appdata_full v0, appdata_full v1, appdata_full v2) {
            return 21;
        }
        //"Wave (x = speed,y = amplitude,z = steepness,w = wavelength)
/*        void SampleWave2(float4 wave, float2 direction, float2 coordinate, inout float3 tangent, inout float3 binormal, inout float3 position){
            float speed = wave.x,
                  amplitude = wave.y,
                  steepness = wave.z, 
                  wavelength = wave.w;
                  direction = normalize(direction);

            float frequency =  UNITY_PI * 2.0 / wavelength;//Also known as K
       //     float function = frequency * amplitude * (dot(direction, coordinate.xy) + speed * _Time.z);
            float function = frequency * (dot(direction, coordinate.xy) + speed * _Time.z);

            tangent += normalize(
                float3(
                    1 - direction.x * direction.x * (steepness * sin(function)),
                    direction.x * (steepness * cos(function)),
                    -direction.x * direction.y * (steepness * sin(function)))
                );

            binormal += 
                float3(
                    -direction.x * direction.y * (steepness * sin(function)),
                    direction.y * (steepness * cos(function)),
                    1 - direction.y * direction.y * (steepness * sin(function))
                );

            position += 
                float3(
                    coordinate.x + direction.x * (steepness * cos(function)),
                    steepness * sin(function),
                    coordinate.y + direction.y * (steepness * cos(function))
                );
        }*/
        void SampleWave(float4 wave, float2 coordinate, inout float3 tangent, inout float3 binormal, inout float3 position){
            float  k = 2 / wave.w;
            float  c = sqrt(9.8 / k);
            float2 d = normalize(wave.xy);
            float  f = k * (dot(d, coordinate.xy) + c * _Time.y);
            float  a = wave.z / k;

      
            tangent += normalize(
                float3(
                    1 - d.x * d.x * (wave.z * sin(f)),
                    d.x *           (wave.z * cos(f)),
                    -d.x * d.y *    (wave.z * sin(f)))
                );

            binormal += 
                float3(
                    -d.x * d.y *    (wave.z * sin(f)),
                    d.y *           (wave.z * cos(f)),
                    1 - d.y * d.y * (wave.z * sin(f))
                );

            position += 
                float3(
                    coordinate.x + d.x * (a * cos(f)),
                                          a * sin(f),
                    coordinate.y + d.y * (a * cos(f))
                );
        }

        void vert(inout appdata_full data) {
            
            
            float3 tangent = 0;
            float3 binormal = 0;
            float3 position = 0;

           
            SampleWave(_WaveA, data.vertex.xz, tangent, binormal, position);
            SampleWave(_WaveB, data.vertex.xz, tangent, binormal, position);
            SampleWave(_WaveC, data.vertex.xz, tangent, binormal, position);

           /* SampleWave(_WaveD, data.vertex.xz, Dtangent, Dbinormal, Dposition);
            SampleWave(_WaveE, data.vertex.xz, Dtangent, Dbinormal, Dposition);
            SampleWave(_WaveF, data.vertex.xz, Dtangent, Dbinormal, Dposition);
            SampleWave(_WaveG, data.vertex.xz, Dtangent, Dbinormal, Dposition);
            SampleWave(_WaveH, data.vertex.xz, Dtangent, Dbinormal, Dposition);
            */ 

            float3 normal = normalize(cross(binormal, tangent));
            //float3 Dnormal = normalize(cross(Dbinormal, Dtangent));



            
            data.vertex.xyz  = position/3;
            //Dposition = Dposition/5;
            //data.vertex.xyz = (position + Dposition )/2;
            //data.normal = (normalize(normal + Dnormal));
            data.normal.xyz = normal;
            data.tangent.xyz = tangent;
            //data.tangent.xyz = normalize(tangent + Dtangent);
            data.color.rgb = data.normal.xyz;
            data.color.g = position.y;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {

            fixed4 c = tex2D (_MainTex, IN.color.xz*0.5 +0.5) * _Color;
            o.Albedo = _Color;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
