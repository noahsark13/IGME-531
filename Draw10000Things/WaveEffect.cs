using UnityEngine;

public class WaveEffect : MonoBehaviour
{
    public float waveSpeed = 1f;

    public float waveFrequency = 0.5f;

    public Vector3 waveDirection = Vector3.right;

    public float hueShiftSpeed = 0.5f;

    [Range(0f, 1f)]
    public float saturation = 0.8f;

    [Range(0f, 1f)]
    public float brightness = 1f;

    public bool enableEmission = true;

    public float emissionIntensity = 2f;

    public bool animateScale = false;

    public float scaleAmount = 0.2f;

    private Renderer[] teapotRenderers;
    private Material[] teapotMaterials;
    private Vector3[] teapotPositions;
    private Transform[] teapotTransforms;
    private float time;
    private bool isInitialized = false;

    void Start()
    {
        CacheTeapots();
    }

    void CacheTeapots()
    {
        teapotRenderers = GetComponentsInChildren<Renderer>();
        teapotPositions = new Vector3[teapotRenderers.Length];
        teapotTransforms = new Transform[teapotRenderers.Length];
        teapotMaterials = new Material[teapotRenderers.Length];

        // cache positions and create material instances
        for (int i = 0; i < teapotRenderers.Length; i++)
        {
            teapotPositions[i] = teapotRenderers[i].transform.position;
            teapotTransforms[i] = teapotRenderers[i].transform;
            teapotMaterials[i] = teapotRenderers[i].material; 

            if (enableEmission && teapotMaterials[i].HasProperty("_EmissionColor"))
            {
                teapotMaterials[i].EnableKeyword("_EMISSION");
            }
        }

        isInitialized = true;
    }

    void Update()
    {
        if (!isInitialized || teapotRenderers == null || teapotRenderers.Length == 0)
            return;

        time += Time.deltaTime;
        Vector3 normalizedDirection = waveDirection.normalized;

        for (int i = 0; i < teapotRenderers.Length; i++)
        {
            if (teapotRenderers[i] == null) continue;

            // calculate wave value based on position
            float distance = Vector3.Dot(teapotPositions[i], normalizedDirection);
            float waveValue = Mathf.Sin((distance * waveFrequency) + (time * waveSpeed));

            // normalize
            float t = (waveValue + 1f) * 0.5f;

            // calculate HSV color
            float hue = Mathf.Repeat(t + (time * hueShiftSpeed * 0.1f), 1f);
            Color color = Color.HSVToRGB(hue, saturation, brightness);

            teapotMaterials[i].color = color;

            if (enableEmission && teapotMaterials[i].HasProperty("_EmissionColor"))
            {
                Color emissionColor = color * emissionIntensity;
                teapotMaterials[i].SetColor("_EmissionColor", emissionColor);
            }

            // scale animation
            if (animateScale && teapotTransforms[i] != null)
            {
                float scale = 1f + (waveValue * scaleAmount);
                float baseScale = 1f; 
                teapotTransforms[i].localScale = Vector3.one * scale * baseScale;
            }
        }
    }

}
