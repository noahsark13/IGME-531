Shader "Custom/NewUnlitUniversalRenderPipelineShader"
{
    Properties
    {
        _FleshColor1 ("Flesh Color 1 (Dark)", Color) = (0.15, 0.05, 0.08, 1)
        _FleshColor2 ("Flesh Color 2 (Mid)", Color) = (0.3, 0.12, 0.15, 1)
        _FleshColor3 ("Flesh Color 3 (Light)", Color) = (0.45, 0.2, 0.25, 1)
        _VeinColor ("Vein Color", Color) = (0.6, 0.15, 0.3, 1)
        _EmissionColor ("Vein Glow Color", Color) = (1.0, 0.3, 0.5, 1)
        _EmissionIntensity ("Glow Intensity", Range(0, 10)) = 4.0
        _Smoothness ("Smoothness", Range(0,1)) = 0.4
        _Metallic ("Metallic", Range(0,1)) = 0.1
        
        // Flesh texture controls
        _FleshScale ("Flesh Scale", Range(0.1, 10)) = 2.0
        _FleshDetail ("Flesh Detail", Range(1, 8)) = 5
        _FleshContrast ("Flesh Contrast", Range(0, 2)) = 1.2
        _FleshSpeed ("Flesh Pulse Speed", Range(0, 2)) = 0.3
        
        // Normal controls (based on flesh)
        _NormalStrength ("Normal Strength", Range(0, 3)) = 0.8
        _CellBulge ("Cell Bulge Amount", Range(0, 2)) = 0.6
        _WrinkleDepth ("Wrinkle Depth", Range(0, 1)) = 0.4
        
        // Vein controls
        _VeinScale ("Vein Network Scale", Range(0.1, 10)) = 3.0
        _VeinSpeed ("Vein Flow Speed", Range(0, 1)) = 0.15
        _VeinThickness ("Vein Thickness", Range(0, 0.5)) = 0.08
        _VeinIntensity ("Vein Intensity", Range(0, 3)) = 1.5
        _VeinDensity ("Vein Density", Range(1, 10)) = 6
        _VeinSharpness ("Vein Sharpness", Range(2, 20)) = 12.0
        _VeinDepth ("Vein Depression Depth", Range(0, 1)) = 0.3
        _VeinFleshFollow ("Vein Follow Flesh", Range(0, 2)) = 1.0
        
        // Vein pulse/flow
        _PulseFlowSpeed ("Pulse Flow Speed", Range(0, 3)) = 1.0
        _PulseFlowScale ("Pulse Flow Scale", Range(0.1, 5)) = 1.5
        _PulseIntensity ("Pulse Intensity", Range(0, 2)) = 1.0
        
        // Breathing pulse
        _BreathSpeed ("Breath Speed", Range(0, 5)) = 1.5
        _BreathIntensity ("Breath Intensity", Range(0, 1)) = 0.4
        
        // Wetness/slime
        _Wetness ("Wetness", Range(0, 1)) = 0.6
        
        // Overall grotesqueness
        _Distortion ("Organic Distortion", Range(0, 2)) = 1.0
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }
        LOD 200
        
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // Multi-compile directives for all lighting features
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 lightmapUV : TEXCOORD1;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 tangentWS : TEXCOORD2;
                float3 bitangentWS : TEXCOORD3;
                float2 uv : TEXCOORD4;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 5);
                float4 shadowCoord : TEXCOORD6;
            };
            
            CBUFFER_START(UnityPerMaterial)
                half4 _FleshColor1;
                half4 _FleshColor2;
                half4 _FleshColor3;
                half4 _VeinColor;
                half4 _EmissionColor;
                half _EmissionIntensity;
                half _Smoothness;
                half _Metallic;
                float _FleshScale;
                float _FleshDetail;
                float _FleshContrast;
                float _FleshSpeed;
                float _NormalStrength;
                float _CellBulge;
                float _WrinkleDepth;
                float _VeinScale;
                float _VeinSpeed;
                float _VeinThickness;
                float _VeinIntensity;
                float _VeinDensity;
                float _VeinSharpness;
                float _VeinDepth;
                float _VeinFleshFollow;
                float _PulseFlowSpeed;
                float _PulseFlowScale;
                float _PulseIntensity;
                float _BreathSpeed;
                float _BreathIntensity;
                float _Wetness;
                float _Distortion;
            CBUFFER_END
            
            // Hash functions
            float hash(float3 p)
            {
                p = frac(p * 0.3183099 + 0.1);
                p *= 17.0;
                return frac(p.x * p.y * p.z * (p.x + p.y + p.z));
            }
            
            float hash1(float p)
            {
                return frac(sin(p) * 43758.5453);
            }
            
            // 3D Noise
            float noise(float3 x)
            {
                float3 p = floor(x);
                float3 f = frac(x);
                f = f * f * (3.0 - 2.0 * f);
                
                return lerp(
                    lerp(
                        lerp(hash(p + float3(0, 0, 0)), hash(p + float3(1, 0, 0)), f.x),
                        lerp(hash(p + float3(0, 1, 0)), hash(p + float3(1, 1, 0)), f.x),
                        f.y),
                    lerp(
                        lerp(hash(p + float3(0, 0, 1)), hash(p + float3(1, 0, 1)), f.x),
                        lerp(hash(p + float3(0, 1, 1)), hash(p + float3(1, 1, 1)), f.x),
                        f.y),
                    f.z);
            }
            
            // Fractal Brownian Motion
            float fbm(float3 p, int octaves)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 1.0;
                
                for (int i = 0; i < octaves; i++)
                {
                    value += amplitude * noise(p * frequency);
                    frequency *= 2.13;
                    amplitude *= 0.47;
                }
                return value;
            }
            
            // Voronoi cells for flesh-like texture
            float2 voronoi(float3 p)
            {
                float3 n = floor(p);
                float3 f = frac(p);
                
                float minDist = 10.0;
                float secondMin = 10.0;
                
                for (int k = -1; k <= 1; k++)
                for (int j = -1; j <= 1; j++)
                for (int i = -1; i <= 1; i++)
                {
                    float3 neighbor = float3(float(i), float(j), float(k));
                    float3 cellPoint = neighbor + hash(n + neighbor) * 0.7 + 0.15;
                    float3 diff = cellPoint - f;
                    float dist = length(diff);
                    
                    if (dist < minDist)
                    {
                        secondMin = minDist;
                        minDist = dist;
                    }
                    else if (dist < secondMin)
                    {
                        secondMin = dist;
                    }
                }
                
                return float2(minDist, secondMin);
            }
            
            // Domain warping for organic distortion
            float3 domainWarp(float3 p, float time)
            {
                float3 q = float3(
                    fbm(p + float3(0.0, 0.0, time * 0.1), 3),
                    fbm(p + float3(5.2, 1.3, time * 0.15), 3),
                    fbm(p + float3(2.1, 8.7, time * 0.08), 3)
                );
                
                float3 r = float3(
                    fbm(p + 4.0 * q + float3(1.7, 9.2, time * 0.12), 3),
                    fbm(p + 4.0 * q + float3(8.3, 2.8, time * 0.09), 3),
                    fbm(p + 4.0 * q + float3(3.1, 5.4, time * 0.11), 3)
                );
                
                return p + q * _Distortion + r * _Distortion * 0.5;
            }
            
            // Generate flesh components (returns: cells, noise, wrinkles, combined)
            float4 generateFleshComponents(float3 warpedPos)
            {
                // Voronoi cells for muscle fiber look
                float2 voronoiResult = voronoi(warpedPos * 1.5);
                float cells = voronoiResult.y - voronoiResult.x;
                cells = pow(cells, 0.7) * _FleshContrast;
                
                // Multi-scale noise for organic texture
                float fleshNoise = fbm(warpedPos, _FleshDetail);
                
                // Add wrinkles and folds
                float wrinkles = fbm(warpedPos * 3.0, 4);
                wrinkles = pow(abs(wrinkles - 0.5) * 2.0, 2.0);
                
                // Combine for flesh-like appearance
                float combined = cells * 0.4 + fleshNoise * 0.4 + wrinkles * 0.2;
                
                return float4(cells, fleshNoise, wrinkles, combined);
            }
            
            // Get flesh warping offset for veins to follow
            float3 getFleshWarp(float3 p, float time)
            {
                float3 warpedPos = domainWarp(p * _FleshScale, time * _FleshSpeed);
                float4 components = generateFleshComponents(warpedPos);
                
                float cells = components.x;
                float wrinkles = components.z;
                
                // Create a vector field based on flesh features
                float3 offset = float3(
                    (cells - 0.5) * 2.0 - (wrinkles - 0.5),
                    (wrinkles - 0.5) * 2.0 - (cells - 0.5),
                    sin(cells * 6.28) * wrinkles
                );
                
                return offset * _VeinFleshFollow;
            }
            
            // Create grotesque flesh texture
            float4 generateFleshTexture(float3 p, float time)
            {
                // Apply organic distortion
                float3 warpedPos = domainWarp(p * _FleshScale, time * _FleshSpeed);
                
                float4 components = generateFleshComponents(warpedPos);
                float fleshPattern = components.w;
                
                // Map to three flesh tones
                float4 fleshColor;
                if (fleshPattern < 0.33)
                    fleshColor = lerp(_FleshColor1, _FleshColor2, fleshPattern * 3.0);
                else if (fleshPattern < 0.66)
                    fleshColor = lerp(_FleshColor2, _FleshColor3, (fleshPattern - 0.33) * 3.0);
                else
                    fleshColor = lerp(_FleshColor3, _FleshColor2, (fleshPattern - 0.66) * 3.0);
                
                return float4(fleshColor.rgb, fleshPattern);
            }
            
            // Generate a single vein path
            float singleVein(float3 p, float seed)
            {
                // Each vein has its own direction and curvature
                float angle1 = hash1(seed) * 6.28;
                float angle2 = hash1(seed + 1.7) * 6.28;
                
                float3 dir1 = float3(cos(angle1), sin(angle1), 0);
                float3 dir2 = float3(cos(angle2), sin(angle2), sin(angle1 + angle2));
                
                // Project position onto vein direction with some waviness
                float dist1 = dot(p, dir1) + fbm(p * 2.0 + seed * 10.0, 2) * 0.3;
                float dist2 = dot(p, dir2) + fbm(p * 1.5 + seed * 7.3, 2) * 0.4;
                
                // Create the vein line
                float veinDist = length(float2(
                    abs(frac(dist1) - 0.5),
                    abs(frac(dist2) - 0.5)
                ));
                
                // Sharp falloff for thin veins
                float vein = 1.0 - smoothstep(0.0, 0.15, veinDist);
                vein = pow(vein, _VeinSharpness);
                
                return vein;
            }
            
            // Create interconnected vein network
            float generateVeinNetwork(float3 p, float time)
            {
                float veins = 0.0;
                
                // Get flesh warping
                float3 fleshOffset = getFleshWarp(p, time);
                
                // Scale and prepare position
                float3 veinPos = p * _VeinScale;
                veinPos += float3(time * _VeinSpeed * 0.2, time * _VeinSpeed * 0.15, 0);
                veinPos += fleshOffset;
                veinPos = domainWarp(veinPos, time * 0.1);
                
                // Generate multiple interconnected vein paths
                for (int i = 0; i < _VeinDensity; i++)
                {
                    float seed = float(i) * 3.141592;
                    
                    // Offset each vein slightly
                    float3 offsetPos = veinPos + float3(
                        hash1(seed) * 2.0 - 1.0,
                        hash1(seed + 1.1) * 2.0 - 1.0,
                        hash1(seed + 2.3) * 2.0 - 1.0
                    ) * 0.5;
                    
                    // Generate vein at this position
                    float vein = singleVein(offsetPos, seed);
                    
                    // Vary thickness per vein
                    float thicknessVariation = hash1(seed + 3.7) * 0.5 + 0.5;
                    vein *= thicknessVariation;
                    
                    veins += vein;
                }
                
                // Add smaller branching veins between main veins
                for (int j = 0; j < _VeinDensity / 2; j++)
                {
                    float seed = float(j) * 2.718 + 100.0;
                    
                    float3 branchPos = veinPos * 1.7 + float3(
                        hash1(seed) * 3.0,
                        hash1(seed + 1.3) * 3.0,
                        hash1(seed + 2.1) * 3.0
                    );
                    
                    float branch = singleVein(branchPos, seed);
                    branch *= 0.4; // Thinner branches
                    
                    veins += branch;
                }
                
                // Add very fine capillary network
                float3 capPos = veinPos * 2.5;
                float capillaries = fbm(capPos, 4);
                capillaries = abs(capillaries - 0.5) * 2.0;
                capillaries = 1.0 - capillaries;
                capillaries = pow(max(capillaries, 0.0), 15.0);
                veins += capillaries * 0.3;
                
                // Normalize
                veins = saturate(veins);
                
                return veins;
            }
            
            // Generate flowing pulse through veins
            float generateVeinPulse(float3 p, float time)
            {
                float3 pulsePos = p * _PulseFlowScale;
                
                // Multi-directional flow
                float flow1 = sin(pulsePos.x - time * _PulseFlowSpeed) * 0.5 + 0.5;
                float flow2 = sin(pulsePos.y * 0.7 - time * _PulseFlowSpeed * 1.3) * 0.5 + 0.5;
                float flow3 = sin(pulsePos.z * 0.5 - time * _PulseFlowSpeed * 0.8) * 0.5 + 0.5;
                
                float pulse = (flow1 + flow2 + flow3) / 3.0;
                pulse = pow(pulse, 3.0);
                pulse *= (noise(p * 2.0 + time * 0.5) * 0.3 + 0.7);
                
                return pulse * _PulseIntensity;
            }
            
            // Calculate height map from flesh components for normal mapping
            float calculateFleshHeight(float3 p, float time)
            {
                float3 warpedPos = domainWarp(p * _FleshScale, time * _FleshSpeed);
                float4 components = generateFleshComponents(warpedPos);
                
                float cells = components.x;
                float fleshNoise = components.y;
                float wrinkles = components.z;
                
                float height = cells * _CellBulge;
                height -= wrinkles * _WrinkleDepth;
                height += fleshNoise * 0.2;
                
                return height;
            }
            
            // Calculate normals from flesh texture
            float3 calculateFleshNormal(float3 p, float time, float veinMask)
            {
                float epsilon = 0.01;
                
                float center = calculateFleshHeight(p, time);
                float right = calculateFleshHeight(p + float3(epsilon, 0, 0), time);
                float up = calculateFleshHeight(p + float3(0, epsilon, 0), time);
                
                float dx = (right - center) / epsilon;
                float dy = (up - center) / epsilon;
                
                float3 normal = float3(-dx, -dy, 1.0);
                normal.z -= veinMask * _VeinDepth;
                normal.xy *= _NormalStrength;
                
                return normalize(normal);
            }
            
            // Breathing pulse effect
            float breathPulse(float time)
            {
                float heartbeat = sin(time * _BreathSpeed) * 0.5 + 0.5;
                heartbeat = pow(heartbeat, 2.0);
                return heartbeat * _BreathIntensity;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.tangentWS = normalInput.tangentWS;
                output.bitangentWS = normalInput.bitangentWS;
                output.uv = input.uv;
                
                // Calculate shadow coordinates
                output.shadowCoord = GetShadowCoord(vertexInput);
                
                // Handle lightmap or SH (spherical harmonics for ambient)
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                
                return output;
            }
            
            half4 frag(Varyings input) : SV_Target
            {
                float time = _Time.y;
                
                // Generate grotesque flesh texture
                float4 fleshData = generateFleshTexture(input.positionWS, time);
                half3 fleshColor = fleshData.rgb;
                float fleshPattern = fleshData.a;
                
                // Generate interconnected vein network
                float veinPattern = generateVeinNetwork(input.positionWS, time);
                veinPattern *= _VeinIntensity;
                
                // Smooth vein edges
                float veinMask = smoothstep(_VeinThickness, _VeinThickness + 0.05, veinPattern);
                
                // Generate flowing pulse through veins
                float veinPulse = generateVeinPulse(input.positionWS, time);
                
                // Breathing pulse effect
                float breathAmount = breathPulse(time);
                
                // Blend veins with flesh
                half3 albedo = lerp(fleshColor, _VeinColor.rgb, veinMask * 0.8);
                
                // Emission for glowing veins with flowing pulse
                float emissionMask = veinMask * veinPulse * (1.0 + breathAmount * 0.5);
                emissionMask = pow(emissionMask, 1.2);
                half3 emission = _EmissionColor.rgb * _EmissionIntensity * emissionMask;
                
                // Calculate normal based on flesh texture
                float3 proceduralNormal = calculateFleshNormal(input.positionWS, time, veinMask);
                
                // Transform to world space
                float3x3 TBN = float3x3(
                    input.tangentWS,
                    input.bitangentWS,
                    input.normalWS
                );
                float3 worldNormal = normalize(mul(proceduralNormal, TBN));
                
                // Wetness affects smoothness
                float wetSmoothness = _Smoothness + _Wetness * 0.4;
                wetSmoothness = lerp(wetSmoothness, _Smoothness * 0.7, veinMask);
                
                // Setup InputData for lighting
                InputData lightingInput = (InputData)0;
                lightingInput.positionWS = input.positionWS;
                lightingInput.normalWS = worldNormal;
                lightingInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                lightingInput.shadowCoord = input.shadowCoord;
                lightingInput.fogCoord = 0;
                lightingInput.vertexLighting = half3(0, 0, 0);
                
                // Sample GI for lightmaps and SH
                lightingInput.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, worldNormal);
                
                lightingInput.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                lightingInput.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
                
                // Setup SurfaceData
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = albedo;
                surfaceData.metallic = _Metallic;
                surfaceData.smoothness = saturate(wetSmoothness);
                surfaceData.normalTS = float3(0, 0, 1);
                surfaceData.emission = emission;
                surfaceData.occlusion = 1.0;
                surfaceData.alpha = 1.0;
                surfaceData.clearCoatMask = 0;
                surfaceData.clearCoatSmoothness = 0;
               
                return UniversalFragmentPBR(lightingInput, surfaceData);
            }
            ENDHLSL
        }
        
        // Shadow casting pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        // Depth pass
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            
            ZWrite On
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
    
    FallBack "Universal Render Pipeline/Lit"
}
