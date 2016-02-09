using UnityEngine;
using System.Collections;

public class ViewInverseCalculator : MonoBehaviour
{
	// Attach this script to any object that needs a ViewInverse matrix supplied
	// It is needed to get View Inverse Matrix into the shader; without it, the effect will not be influenced by the camera

	// GameObject camera;
	public Camera cam;

	// Use this for initialization
	void Start ()
	{
		// Attempt to grab the main camera in the scene
		cam = Camera.main;
	}
	
	// Update is called once per frame
	void Update ()
	{
		if(cam)
		{
			// Set translation, rotation, and scale for the new matrix
			Matrix4x4 scaleOffset = Matrix4x4.TRS(new Vector3(0f, 0f, 0f),
				Quaternion.identity, new Vector3(0.5f, 0.5f, 0.5f));
			
			Matrix4x4 ViewInverse = (scaleOffset * cam.projectionMatrix * cam.worldToCameraMatrix * transform.localToWorldMatrix);
			Debug.DrawLine(Vector3.zero, new Vector3(ViewInverse[3, 0], -ViewInverse[3, 1], ViewInverse[3, 2]), Color.red);
			
			// TODO: Try to consolidate the rotation change from the shader into these calculations
			// as well as figure out why the vector isn't updating with the WASD movement of the camera
			// Flip Y axis
			ViewInverse[3, 1] = -ViewInverse[3, 1];
			
			renderer.material.SetMatrix("ViewInverse", ViewInverse);
		}
	}
}