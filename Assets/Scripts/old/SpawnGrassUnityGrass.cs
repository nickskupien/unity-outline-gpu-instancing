using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpawnGrassUnityGrass : MonoBehaviour
{

    // [SerializeField]
    // Terrain activeTerrain;

    //Unity says this is the main terrain of the scene
    public static Terrain activeTerrain;

    // Start is called before the first frame update
     void Start()
    {
        var grassDensity = 128;
        var patchDetail = 16;
        activeTerrain = transform.gameObject.GetComponent<Terrain>();
        activeTerrain.terrainData.SetDetailResolution(grassDensity, patchDetail);
    
        int[,] newMap = new int[grassDensity, grassDensity];
    
        for (int i = 0; i < grassDensity; i++)
        {
            for (int j = 0; j < grassDensity; j++)
            {
                // // Sample the height at this location (note GetHeight expects int coordinates corresponding to locations in the heightmap array)
                // float height = activeTerrain.terrainData.GetHeight( i, j );
                // if (height < 10.0f)
                // {
                //     newMap[i, j] = 1;
                // }
                // else
                // {
                //     newMap[i, j] = 0;
                // }
                newMap[i,j] = 1;
            }
        }
        activeTerrain.terrainData.SetDetailLayer(0, 0, 0, newMap);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
