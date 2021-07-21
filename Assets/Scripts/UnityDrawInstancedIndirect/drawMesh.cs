using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Starter code from: https://toqoz.fyi/thousands-of-meshes.html

public class drawMesh : MonoBehaviour {
    public int population;
    public float range;
    public float grassOffset = 1;
    public float grassWidthScale = 0.5f;
    public float grassHeightScale = 0.5f;

    [SerializeField]
    public Terrain activeTerrain;

    public Material material;
    public ComputeShader compute;
    public Transform pusher;
    public Camera cam;
    public Matrix4x4 rotationTransformation;

    private ComputeBuffer meshPropertiesBuffer;
    private ComputeBuffer argsBuffer;

    private Mesh mesh;
    private Bounds bounds;
    private Vector3[] positions;

    public struct IntVector2
    {
        public int x;
        public int y;
    }

    // Mesh Properties struct to be read from the GPU.
    // Size() is a convenience funciton which returns the stride of the struct.
    private struct MeshProperties {
        public Matrix4x4 mat;
        public float textureid;
        public Vector4 color;

        public static int Size() {
            return
                sizeof(float) * 4 * 4 + // matrix;
                sizeof(float) +       // texture type;
                sizeof(float) * 4;      // color;
        }
    }

    private void Setup() {
        Mesh mesh = CreateQuad();
        this.mesh = mesh;

        // Boundary surrounding the meshes we will be drawing.  Used for occlusion.
        bounds = new Bounds(transform.position, Vector3.one * (range + 1));

        InitializeBuffers();
    }

    private void InitializeBuffers() {
        int kernel = compute.FindKernel("CSMain");

        // Argument buffer used by DrawMeshInstancedIndirect.
        uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
        // Arguments for drawing mesh.
        // 0 == number of triangle indices, 1 == population, others are only relevant if drawing submeshes.
        args[0] = (uint)mesh.GetIndexCount(0);
        args[1] = (uint)population;
        args[2] = (uint)mesh.GetIndexStart(0);
        args[3] = (uint)mesh.GetBaseVertex(0);
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);

        // Initialize buffer with the given population.
        MeshProperties[] properties = new MeshProperties[population];
        positions = new Vector3[population];

        var terrainData = activeTerrain.terrainData;
        var terrainSize = terrainData.size;
        var terrainOffset = activeTerrain.transform.position;

        for (int i = 0; i < population; i++) {
            MeshProperties props = new MeshProperties();

            float grassX = Random.Range(terrainOffset.x, terrainOffset.x+terrainSize.x);
            float grassZ = Random.Range(terrainOffset.z, terrainOffset.z+terrainSize.z);

            float grassY = activeTerrain.SampleHeight(new Vector3(grassX, 0, grassZ)) + grassOffset;

            Vector3 position = new Vector3(grassX, grassY, grassZ);
            positions[i] = position;
            Quaternion rotation = Quaternion.Euler(Random.Range(-180, 180), Random.Range(-180, 180), Random.Range(-180, 180));
            Vector3 scale = Vector3.one;

            props.mat = Matrix4x4.TRS(position, rotation, scale);
            // props.color = Color.Lerp(Color.red, Color.blue, Random.value);
            props.textureid = Random.Range(0,7);

            properties[i] = props;
        }

        meshPropertiesBuffer = new ComputeBuffer(population, MeshProperties.Size());
        meshPropertiesBuffer.SetData(properties);
        compute.SetBuffer(kernel, "_Properties", meshPropertiesBuffer);
        material.SetBuffer("_Properties", meshPropertiesBuffer);
    }

    private Mesh CreateQuad(float width = 1f, float height = 1f) {
        // Create a quad mesh.
        var mesh = new Mesh();

        float w = width * grassWidthScale;
        float h = height * grassHeightScale;
        var vertices = new Vector3[4] {
            new Vector3(-w, -h, 0),
            new Vector3(w, -h, 0),
            new Vector3(-w, h, 0),
            new Vector3(w, h, 0)
        };

        var tris = new int[6] {
            // lower left tri.
            0, 2, 1,
            // lower right tri
            2, 3, 1
        };

        var normals = new Vector3[4] {
            -Vector3.forward,
            -Vector3.forward,
            -Vector3.forward,
            -Vector3.forward,
        };

        var uv = new Vector2[4] {
            new Vector2(0, 0),
            new Vector2(1, 0),
            new Vector2(0, 1),
            new Vector2(1, 1),
        };

        mesh.vertices = vertices;
        mesh.triangles = tris;
        mesh.normals = normals;
        mesh.uv = uv;

        return mesh;
    }

    private void OnEnable() {
        Setup();
    }

    private void Update() {
        int kernel = compute.FindKernel("CSMain");

        Vector3 position = positions[0];

        rotationTransformation = Matrix4x4.LookAt(position, cam.transform.position, Vector3.up);

        // rotationTransformation = Matrix4x4.Rotate(rotationTransformation.rotation);

        rotationTransformation = Matrix4x4.Rotate(cam.transform.rotation);

        compute.SetMatrix("_PusherRotation", rotationTransformation);
        compute.SetInt("_Resolution", population);
        // We used to just be able to use `population` here, but it looks like a Unity update imposed a thread limit (65535) on my device.
        // This is probably for the best, but we have to do some more calculation.  Divide population by numthreads.x in the compute shader.
        compute.Dispatch(kernel, Mathf.CeilToInt(population / 64f), 1, 1);
        Graphics.DrawMeshInstancedIndirect(mesh, 0, material, bounds, argsBuffer);
    }

    private void OnDisable() {
        if (meshPropertiesBuffer != null) {
            meshPropertiesBuffer.Release();
        }
        meshPropertiesBuffer = null;

        if (argsBuffer != null) {
            argsBuffer.Release();
        }
        argsBuffer = null;
    }
}