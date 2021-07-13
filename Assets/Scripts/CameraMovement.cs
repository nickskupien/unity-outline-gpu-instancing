using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    [Range(0f, 100f)]
    public float rotationSpeed = 50;

    [Range(0f, 10f)]
    public float panSpeed = 3;

    public float pitch = 30;
    private Vector2 orbitAngles = new Vector2(30,45f);
    private Vector3 focusPoint = new Vector3(0,10,0);

    public float distance = 500;
    public float posY = 35;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void LateUpdate()
    {
        orbitAngles.y += Input.GetAxis("Mouse X") * rotationSpeed * Time.unscaledDeltaTime * Input.GetAxis("Fire1");
        orbitAngles.x = pitch;
        posY += Input.GetAxis("Vertical") * panSpeed * Time.unscaledDeltaTime;
        Quaternion lookRotation = Quaternion.Euler(orbitAngles);
        Vector3 lookDirection = lookRotation * Vector3.forward;
        Vector3 lookPosition = focusPoint - lookDirection * distance;
        transform.SetPositionAndRotation(lookPosition, lookRotation);
    }
}
