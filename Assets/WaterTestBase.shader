Shader "Custom/WaterTestBase"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Amount ("Extrusion Amount", Range(-10,10)) = 0.5
        _Tess ("Tessellation", Range(1,32)) = 4
        
        _BaseScale("Base Height Scale", Float) = 1.0
        _BaseMidPoint("Base Height Mid Point", Float) = 1.0
        
        _BaseColorHigh("Base High Color", Color) = (1,1,1,1)
        _BaseColorLow("Base Low Color", Color) = (1,1,1,1)
        

        _DtalScale("Detail Height Scale", Float) = 1.0
        _DtalMidPoint("Detail Height Mid Point", Float) = 1.0
        
        _DtalColorHigh("Detail High Color", Color) = (1,1,1,1)
        _DtalColorLow("Detail Low Color",Color) = (1,1,1,1)

        _ColorMergeFactor("Color Merge factor", Float) = 2.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tessDistance addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 4.6
        #include "Tessellation.cginc"
        
        sampler2D _MainTex;
        float _Tess;
        struct appdata
        {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
           // float2 texcoord : TEXCOORD0;
    
            // we will use this to pass custom data to the surface function
            fixed4 color : COLOR;
        };
        float4 tessDistance (appdata v0, appdata v1, appdata v2) {
            float minDist = 1.0;
            float maxDist = 120.0;
            return _Tess;// UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
        }

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _Amount;
        
        fixed3 _DtalColorHigh;
        fixed3 _DtalColorLow;
        float  _DtalScale;
        float  _DtalMidPoint;

        fixed3 _BaseColorHigh;
        fixed3 _BaseColorLow;
        float  _BaseScale;
        float  _BaseMidPoint;
        float _ColorMergeFactor;
        struct Input{
            fixed3 color : COLOR;

        };
        

        struct Wave{
            float waveLength;
            float amplitude;
            float speed;
            float2 direction;
            float steepness;
        };

        struct WaveResult
        {
            float3 position;
            float3 bitangent;
            float3 tangent;
        };
        float F(float2 direction, float2 coordinate, float phi, float frequency){
            return frequency * dot(direction, coordinate) + phi * _Time.z;
        }

        WaveResult CalculateWave(Wave wave, float2 coordinate, float waveCount){
            WaveResult result;

            float frequency = 2.0 / wave.waveLength;
            float phi = wave.speed * frequency;
            float qi = wave.steepness / (wave.amplitude * frequency * waveCount);
            float f = F(wave.direction, coordinate, phi, frequency);
        
            result.position.x = qi * wave.amplitude * wave.direction.x * cos(f);
            result.position.z = qi * wave.amplitude * wave.direction.y * cos(f);
            result.position.y = wave.amplitude * sin(f);

            f = F(wave.direction, result.position.xz, phi, frequency);
            float waFactor = frequency * wave.amplitude;

            result.tangent.x = -1 * (qi * wave.direction.x * wave.direction.y * waFactor * sin(f));
            result.tangent.z = 1 - (qi * wave.direction.y * wave.direction.y * waFactor * sin(f));
            result.tangent.y = wave.direction.y * waFactor * cos(f);
           
            result.bitangent.x = 1 - (qi * wave.direction.x * wave.direction.x * waFactor * sin(f));
            result.bitangent.z = -1 * (qi * wave.direction.x * wave.direction.y * waFactor * sin(f));
            result.bitangent.y = wave.direction.x * waFactor * cos(f);

            result.tangent = normalize(result.tangent);
            result.bitangent = normalize(result.bitangent);

            return result;
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

    void CalculateBaseWavefront(inout float3 position, inout float3 normal){
        Wave waves[3];

        waves[0].direction = normalize(float2(0.1, -0.7));
        waves[0].steepness = 1.2;
        waves[0].waveLength = 5.2;
        waves[0].amplitude = 0.65;
        waves[0].speed = 1.21;
    
        waves[1].direction = normalize(float2(-0.743, 0.6691));
        waves[1].steepness = 0.7;
        waves[1].waveLength = 4.1;
        waves[1].amplitude = 0.37;
        waves[1].speed = 2.03;
  
        waves[2].direction = normalize(float2(0.9, 0.1));
        waves[2].steepness = 1.5;
        waves[2].waveLength = 2.6;
        waves[2].amplitude = 0.63;
        waves[2].speed = 2.73;
    
        float3 bitangent = 0;
        float3 tangent = 0;
        float2 coordinate = position.xz;
        position.y = 0;
        for(uint waveId = 0; waveId < 3; waveId++)
        {
            WaveResult waveResult = CalculateWave(waves[waveId], coordinate, 3.0);
            position  += waveResult.position;
            bitangent += waveResult.bitangent;
            tangent   += waveResult.tangent;
        }


     //   position.xz += position.xz;
        normal += cross(normalize(bitangent),normalize(tangent));
    }

    void CalculateDetailWavefront(inout float3 position, inout float3 normal){
        Wave waves[5];

        waves[0].direction = normalize(float2(0.469, 0.8829));
        waves[0].steepness = 3.0;
        waves[0].waveLength = 0.82;
        waves[0].amplitude = 0.03;
        waves[0].speed = 0.478;
    
        waves[1].direction = normalize(float2(0.985, -0.1736));
        waves[1].steepness = 3.5;
        waves[1].waveLength = 0.8;
        waves[1].amplitude = 0.083;
        waves[1].speed = 1.2;
  
        waves[2].direction = normalize(float2(-0.469, -0.0829));
        waves[2].steepness = 2.9;
        waves[2].waveLength = 0.94;
        waves[2].amplitude = 0.037;
        waves[2].speed = 0.686;
 
        waves[3].direction = normalize(float2(-0.891, 0.454));
        waves[3].steepness = 1.1;
        waves[3].waveLength = 0.37;
        waves[3].amplitude = 0.01;
        waves[3].speed = 2.323;
  
        waves[4].direction = normalize(float2(-0.97, -0.2419));
        waves[4].steepness = 2.7;
        waves[4].waveLength = 0.3;
        waves[4].amplitude = 0.023;
        waves[4].speed = 0.28;


        float3 bitangent = 0;
        float3 tangent = 0;
        float2 coordinate = position.xz;
        position.y = 0;
        for(uint waveId = 0; waveId < 5; waveId++)
        {
            WaveResult waveResult = CalculateWave(waves[waveId], coordinate, 3.0);
            position  += waveResult.position;
            bitangent += waveResult.bitangent;
            tangent   += waveResult.tangent;
        }

      //  position.xz += position.xz;
        normal += cross(normalize(bitangent),normalize(tangent));
    }


    void vert (inout appdata v)
    {
        float3 positionBase = v.vertex.xyz;
        float3 positionDetail = v.vertex.xyz;
        float3 normalBase = 0;
        float3 normalDetail = 0;
        CalculateBaseWavefront(positionBase,normalBase);
        CalculateDetailWavefront(positionDetail, normalDetail);

        v.vertex.xyz = (positionBase + positionDetail)*0.5;
        //i need to fix this
        //v.normal = normalize(normalBase+normalDetail);
       
        v.color.x = positionBase.y*0.5;
        v.color.y = positionDetail.y*0.5;
        v.color.z = v.vertex.y;
    }


    void surf (Input IN, inout SurfaceOutputStandard o)
    {
        float dtalHeight = (IN.color.y + _DtalMidPoint) /_DtalScale;
        float baseHeight = (IN.color.x + _BaseMidPoint) /_BaseScale;
        fixed3 baseColor = lerp(_BaseColorLow, _BaseColorHigh, saturate(baseHeight));
        fixed3 dtalColor = lerp(_DtalColorLow, _DtalColorHigh, saturate(dtalHeight));
        o.Albedo.rgb = saturate(baseColor + (baseColor * (dtalColor * saturate((dtalHeight+baseHeight)/_ColorMergeFactor))));

        //o.Albedo.rgb = lerp(float3(0.0,0.3,0.6),float3(0.1,0.6,0.8),IN.color.y);
        o.Metallic = _Metallic;
        o.Smoothness = _Glossiness;
    //    o.Alpha = c.a;
    }
    ENDCG
    }
    FallBack "Diffuse"
    
}
