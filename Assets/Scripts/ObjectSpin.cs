using System;
using UnityEngine;

public class ObjectSpin : MonoBehaviour
{
    const float HOURS_TO_DEGREES = -30f, MINUTES_TO_DEGREES = -6f, SECONDS_TO_DEGREES = -6f;

    [SerializeField]
    Transform cube1,cube2,cube3,icosphere,cylinder,squareonsquare;

    void Update () {
        
        TimeSpan time = DateTime.Now.TimeOfDay;
        float time_degrees = (float)time.TotalSeconds * SECONDS_TO_DEGREES * 5f;
        // float iso = MathF.Asin(1/MathF.Sqrt(3));

        cube1.transform.Rotate(1f, 0f, 1f, Space.Self);
        cube2.transform.Rotate(0f, 1f, 0f, Space.Self);
        icosphere.transform.Rotate(0f,1f,0f, Space.Self);
        cylinder.transform.Rotate(0f,0f,1f, Space.Self);
        squareonsquare.transform.Rotate(0f,1f,0f, Space.Self);
        cube3.localRotation = Quaternion.Euler(time_degrees, time_degrees, time_degrees);


    }
}
