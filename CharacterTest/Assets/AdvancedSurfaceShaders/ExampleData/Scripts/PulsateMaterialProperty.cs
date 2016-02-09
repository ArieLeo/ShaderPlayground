using UnityEngine;

public class PulsateMaterialProperty : MonoBehaviour
{
    public Material material = null;

    public string propertyName = "";

    public float minVal = 0f;

    public float maxVal = 1f;

    public float pulsateSpeed = 1f;

    void Update()
    {
        material.SetFloat(propertyName, Mathf.Lerp(minVal, maxVal, Mathf.PingPong(Time.time * pulsateSpeed, 1f)));
    }
}