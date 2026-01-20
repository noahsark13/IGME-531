using UnityEngine;

public class TeapotInstantiator : MonoBehaviour
{

    public GameObject teapotPrefab;

    public MeshFilter sourceMeshFilter;

    public Transform parentTransform;

    public int targetTeapotCount = 10000;

    public float teapotScale = 0.1f;

    public bool faceOutward = true;


    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        parentTransform = transform;

        InstantiateTeapots();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void InstantiateTeapots()
    {
        Mesh mesh = sourceMeshFilter.sharedMesh;
        if (mesh == null)
        {
            Debug.LogError("Source mesh filter has no mesh!");
            return;
        }


        Vector3[] vertices = mesh.vertices;
        Vector3[] normals = mesh.normals;

        // Calculate sample rate to get close to target count
        int sampleRate = Mathf.Max(1, vertices.Length / targetTeapotCount);
        int actualCount = Mathf.CeilToInt(vertices.Length / (float)sampleRate);

        Debug.Log($"Mesh has {vertices.Length} vertices. Using sample rate of {sampleRate} to create {actualCount} teapots.");

        // Transform to world space
        Transform meshTransform = sourceMeshFilter.transform;

        // Instantiate teapots at vertex pos
        for (int i = 0; i < vertices.Length; i += sampleRate)
        {
            // get world pos of vert
            Vector3 worldPos = meshTransform.TransformPoint(vertices[i]);

            Quaternion rotation = Quaternion.identity;
            if (faceOutward && normals.Length > i)
            {
                Vector3 worldNormal = meshTransform.TransformDirection(normals[i]);
                rotation = Quaternion.LookRotation(worldNormal);
            }

            GameObject teapot = Instantiate(teapotPrefab, worldPos, rotation, parentTransform);
            teapot.transform.localScale = Vector3.one * teapotScale;
        }

    }

}
