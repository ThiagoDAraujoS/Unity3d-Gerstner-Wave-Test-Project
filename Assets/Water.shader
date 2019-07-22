Shader "Custom/Water"
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
            float3 direction;
            float steepness;
        };

        struct WaveResult
        {
            float3 position;
            float3 normal;
            float3 tangent;
        };
 
        WaveResult CalculateWave(Wave wave, float3 samplingPosition, float waveCount){
            WaveResult result;

            float frequency = 2.0 / wave.waveLength;
            float phaseConstant = wave.speed * frequency;
            float qi = wave.steepness / (wave.amplitude * frequency * waveCount);
            float rad = frequency * dot(wave.direction.xz, samplingPosition.xz) + phaseConstant * _Time.z;
            float sinR = sin(rad);
            float cosR = cos(rad);
        
            result.position.x = qi * wave.amplitude * wave.direction.x * cosR;
            result.position.z = qi * wave.amplitude * wave.direction.z * cosR;
            result.position.y = wave.amplitude * sinR;

            float waFactor = frequency * wave.amplitude;
            float radN = frequency * dot(wave.direction, result.position) + _Time.z * phaseConstant;
            float sinN = sin(radN);
            float cosN = cos(radN);

            result.tangent.x = qi * wave.direction.x * wave.direction.z * waFactor * sinN;
            result.tangent.z = qi * wave.direction.z * wave.direction.z * waFactor * sinN;
            result.tangent.y = wave.direction.z * waFactor * cosN;
           
            result.normal.x = wave.direction.x * waFactor * cosN;
            result.normal.z = wave.direction.z * waFactor * cosN;
            result.normal.y = qi * waFactor * sinN;

            return result;
        }

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

    WaveResult CalculateBaseWavefront(float3 position){
        Wave waves[3];

        waves[0].direction = normalize(float3(0.1, 0, -0.7));
        waves[0].steepness = 1.2;
        waves[0].waveLength = 5.2;
        waves[0].amplitude = 0.65;
        waves[0].speed = 1.21;
    
        waves[1].direction = normalize(float3(-0.743, 0, 0.6691));
        waves[1].steepness = 0.7;
        waves[1].waveLength = 4.1;
        waves[1].amplitude = 0.37;
        waves[1].speed = 2.03;
  
        waves[2].direction = normalize(float3(0.9, 0, 0.1));
        waves[2].steepness = 1.5;
        waves[2].waveLength = 2.6;
        waves[2].amplitude = 0.63;
        waves[2].speed = 2.73;

        WaveResult baseWavefront;
        baseWavefront.position = float3(0,0,0);
        baseWavefront.normal = float3(0,0,0);
        baseWavefront.tangent = float3(0,0,0);
    
        for(uint waveId = 0; waveId < 3; waveId++)
        {
            WaveResult waveResult = CalculateWave(waves[waveId], position,3.0);
            baseWavefront.position += waveResult.position;
            baseWavefront.normal += waveResult.normal;
            baseWavefront.tangent += waveResult.tangent;
        }

        baseWavefront.position.xz += position.xz;
        
        
        baseWavefront.normal.xz *= -1.0;
        baseWavefront.normal.y = 1 - baseWavefront.normal.y;
        
        baseWavefront.tangent.x *= -1.0;
        baseWavefront.tangent.z = 1.0 - baseWavefront.tangent.z;
        return baseWavefront;
    }

    WaveResult CalculateDetailWavefront(float3 position){
        Wave waves[5];

        waves[0].direction = normalize(float3(0.469, 0, 0.8829));
        waves[0].steepness = 3.0;
        waves[0].waveLength = 0.82;
        waves[0].amplitude = 0.03;
        waves[0].speed = 0.478;
    
        waves[1].direction = normalize(float3(0.985, 0, -0.1736));
        waves[1].steepness = 3.5;
        waves[1].waveLength = 0.8;
        waves[1].amplitude = 0.083;
        waves[1].speed = 1.2;
  
        waves[2].direction = normalize(float3(-0.469, 0, -0.0829));
        waves[2].steepness = 2.9;
        waves[2].waveLength = 0.94;
        waves[2].amplitude = 0.037;
        waves[2].speed = 0.686;
 
        waves[3].direction = normalize(float3(-0.891, 0, 0.454));
        waves[3].steepness = 1.1;
        waves[3].waveLength = 0.37;
        waves[3].amplitude = 0.01;
        waves[3].speed = 2.323;
  
        waves[4].direction = normalize(float3(-0.97, 0, -0.2419));
        waves[4].steepness = 2.7;
        waves[4].waveLength = 0.3;
        waves[4].amplitude = 0.023;
        waves[4].speed = 0.28;


        WaveResult baseWavefront;
        baseWavefront.position = float3(0,0,0);
        baseWavefront.normal = float3(0,0,0);
        baseWavefront.tangent = float3(0,0,0);
    
        for(uint waveId = 0; waveId < 5; waveId++)
        {
            WaveResult waveResult = CalculateWave(waves[waveId], position,5.0);
            baseWavefront.position += waveResult.position;
            baseWavefront.normal += waveResult.normal;
            baseWavefront.tangent += waveResult.tangent;
        }

        baseWavefront.position.xz += position.xz;
        baseWavefront.normal.xz *= -1.0;
        baseWavefront.normal.y = 1 - baseWavefront.normal.y;
        baseWavefront.tangent.x *= -1.0;
        baseWavefront.tangent.z = 1.0 - baseWavefront.tangent.z;

        return baseWavefront;
    }


    void vert (inout appdata v)
    {
        WaveResult baseWavefront = CalculateBaseWavefront(v.vertex.xyz);
        WaveResult dtalWavefront = CalculateDetailWavefront(v.vertex.xyz);
       // v.normal.xyz = baseWavefront.normal;
        v.vertex.xyz = (baseWavefront.position + dtalWavefront.position)/2.0;
        v.color.x = baseWavefront.position.y/2.0;
        v.color.y = dtalWavefront.position.y/2.0;
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
