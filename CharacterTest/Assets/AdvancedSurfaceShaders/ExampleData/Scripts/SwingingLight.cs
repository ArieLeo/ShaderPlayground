using UnityEngine;

public class SwingingLight : MonoBehaviour
{
    public float swingTime = 5f;

    public Vector3 swingMin = Vector3.zero;
    public Vector3 swingMax = Vector3.zero;

    private Transform thisTransform = null;

    void OnEnable()
    {
        thisTransform = transform;
    }

    void Update()
    {
        thisTransform.localRotation = Quaternion.Slerp(Quaternion.Euler(swingMin), Quaternion.Euler(swingMax), Mathf.PingPong(Time.time * (1f/swingTime), 1f));
    }
}