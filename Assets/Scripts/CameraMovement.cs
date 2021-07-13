using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    [Range(0f, 100f)]
    public float rotationSpeed = 50;
    public float automaticRotationSpeed = 10;

    [Range(0f, 10f)]
    public float panSpeed = 3;

    public float pitch = 30;
    private Vector2 orbitAngles = new Vector2(30,45f);
    private Vector3 focusPoint = new Vector3(0,10,0);

    public float distance = 500;
    public float posY = 35;

    [SerializeField, Range(0f, 90f)]
	float alignSmoothRange = 45f;
    float targetAngle = 45;
    bool rotating = false;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void LateUpdate()
    {
        if(!rotating){
            targetAngle = orbitAngles.y;
        }

        if(Input.GetAxis("Horizontal") > 0.1){
            targetAngle = orbitAngles.y - 45;
            rotating = true;
        }
        else if(Input.GetAxis("Horizontal") < -0.1){
            targetAngle = orbitAngles.y + 45;
            rotating = true;
        }

        targetAngle = Mathf.RoundToInt(targetAngle/45)*45;

        float deltaAbs = Mathf.Abs(Mathf.DeltaAngle(orbitAngles.y, targetAngle));
        float rotationChange = automaticRotationSpeed * Time.unscaledDeltaTime;

        if (deltaAbs < alignSmoothRange) {
			rotationChange *= deltaAbs / alignSmoothRange;
		}

        if (deltaAbs < 10){
            rotating = false;
        }

        if(Input.GetAxis("Fire1") > 0){
            orbitAngles.y += Input.GetAxis("Mouse X") * rotationSpeed * Time.unscaledDeltaTime;
        }
        else{
            orbitAngles.y = Mathf.MoveTowardsAngle(orbitAngles.y, targetAngle, rotationChange);
        }
        
        orbitAngles.x = pitch;

        posY += Input.GetAxis("Vertical") * panSpeed * Time.unscaledDeltaTime;
        Quaternion lookRotation = Quaternion.Euler(orbitAngles);
        Vector3 lookDirection = lookRotation * Vector3.forward;
        Vector3 lookPosition = focusPoint - lookDirection * distance;
        transform.SetPositionAndRotation(lookPosition, lookRotation);
    }
}
