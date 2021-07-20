using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GPUGrass : MonoBehaviour
{

    [SerializeField]
	ComputeShader computeShader;

    [SerializeField]
	Material material;

    [SerializeField]
	Camera mainCamera;

	[SerializeField]
	Mesh mesh;

    const int maxResolution = 1000;

    [SerializeField, Range(10,maxResolution)]
    int grassResolution = 50;

    ComputeBuffer rotationsBuffer;

    static readonly int
        rotationsId = Shader.PropertyToID("_Rotations");
        // indexId = Shader.PropertyToID("_Index");
    
    void UpdateFunctionOnGPU () {
        // computeShader.SetBuffer(rotationsId, rotationsBuffer);

    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        UpdateFunctionOnGPU();
    }

    // could use awake but instead we use OnEnable because it survives a hot reloat
	void OnEnable () {
        // 3*4 is the size of 3 float numbers (4 bytes each)
		rotationsBuffer = new ComputeBuffer(grassResolution*grassResolution,3*4);
	}

    // destructor
    void OnDisable () {
		rotationsBuffer.Release();
        // get rid of reference to it so Unity can collect for garbage collecting
        rotationsBuffer = null;
	}
}
