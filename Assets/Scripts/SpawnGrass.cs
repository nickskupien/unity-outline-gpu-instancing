using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpawnGrass : MonoBehaviour
{

    // [SerializeField]
    // Terrain activeTerrain;

    //Unity says this is the main terrain of the scene
    [SerializeField]
    public Terrain activeTerrain;
    public float grassOffset;
    public float grassDensityPerTerrainScale = 1.5f;

    public string grassPrefabsFolder;
    public List<GameObject> grassObjects = new List<GameObject>();

    // Start is called before the first frame update
     void Start()
    {
        var grassObjectsResource = Resources.LoadAll(grassPrefabsFolder);

        foreach(var grassObject in grassObjectsResource){
            grassObjects.Add(grassObject as GameObject);
        }

        // activeTerrain = transform.gameObject.GetComponent<Terrain>();
        var terrainData = activeTerrain.terrainData;

        var terrainScale = terrainData.heightmapScale.y;
        var terrainSize = terrainData.size;
        int grassDensity = Mathf.FloorToInt(terrainSize.x*grassDensityPerTerrainScale);
        var terrainOffset = activeTerrain.transform.position;
        // var terrainResolution = terrainData.heightmapResolution;
        float interpolatedDistance = 1.0f/grassDensity;
        var terrainHeight = terrainData.GetInterpolatedHeights(0,0,grassDensity,grassDensity,interpolatedDistance,interpolatedDistance);
        Vector3 distanceBetweenGrass = terrainSize/grassDensity;
        
        for (int y = 0; y < grassDensity; y++){
            for (int x = 0; x < grassDensity; x++){
                float grassY = terrainHeight[y,x] + grassOffset;
                float grassX = terrainOffset.x + distanceBetweenGrass.x*x + Random.Range(0, distanceBetweenGrass.x);
                float grassZ = terrainOffset.z + distanceBetweenGrass.z*y + Random.Range(0, distanceBetweenGrass.z);

                // Debug.Log(y%2);

                // Debug.Log("number of grass objects: " + grassObjects.Count);

                int grassPrefabToUse = Random.Range(0, grassObjects.Count-1);

                Instantiate(grassObjects[grassPrefabToUse], new Vector3(grassX,grassY,grassZ), Quaternion.identity, transform);
            }
        }       
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void changeSprite(Sprite sprite, GameObject toChange) { 
        toChange.GetComponent<SpriteRenderer>().sprite = sprite; 
    }
}
