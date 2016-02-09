using UnityEngine;
using System.Collections;

/// <summary>
/// Handles orbiting a camera around a transform based on mouse input while looking at it
/// </summary>
public class OrbitCamera : MonoBehaviour
{
    /// <summary>
    /// The transform to orbit
    /// </summary>
    public      Transform           target;

    /// <summary>
    /// The distance of the orbit from the target
    /// </summary>
    public      float               distance = 10f;

    /// <summary>
    /// The speed at which to orbit based on mouse input
    /// </summary>
    public float speed = 2f;

    /// <summary>
    /// The zoom speed
    /// </summary>
    public float zoomSpeed = 2f;

    /// <summary>
    /// The Distance speed when the camera is at its min Distance level
    /// </summary>
    public      float               minDistanceSpeed = 1f;
    
    /// <summary>
    /// The Distance speed when the camera is at its max Distance level
    /// </summary>
    public      float               maxDistanceSpeed = 100f;
    
    /// <summary>
    /// The minimum amount a camera can Distance
    /// </summary>
    public      float               minDistance = 1f;
    
    /// <summary>
    /// The maximum amount the camera can Distance
    /// </summary>
    public      float               maxDistance = 200f;

    /// <summary>
    /// Amount to increase speed of actions when shift is held down
    /// </summary>
    public      float               shiftKeyModifier = 2.5f;

    /// <summary>
    /// The current x orbit position
    /// </summary>
    private     float               x = 0f;

    /// <summary>
    /// The current y orbit position
    /// </summary>
    private     float               y = 0f;

    /// <summary>
    /// The cached transform of this gameobject for speed purposes
    /// </summary>
    private     Transform           thisTransform;

    private     Vector3             previousTargetPos = Vector3.zero;

    #region Properties

    /// <summary>
    /// Returns the transform of the object and assigns the cached transform var if not already defined
    /// </summary>
    public Transform xform
    {
        get
        {
            if ( thisTransform == null ) thisTransform = transform;
            return thisTransform;
        }
    }

    #endregion

    /// <summary>
    /// Calls the setup method on startup
    /// </summary>
    void Start ()
    {
        Setup();
    }

    /// <summary>
    /// Handles the orbiting
    /// </summary>
    void LateUpdate ()
    {
        float speedMod = 1f;
        if ( Input.GetKey( KeyCode.LeftShift ) || Input.GetKey( KeyCode.RightShift ) )
        {
            speedMod = shiftKeyModifier;
        }

        // We have a target to do anything
        if ( target != null )
        {
            bool hasChanged = false;

            if ( target.position != previousTargetPos )
            {
                hasChanged = true;
            }

            // Check for scrollwheel Distanceing
            float scrollWheel = Input.GetAxis( "Mouse ScrollWheel" );
            if ( scrollWheel != 0f )
            {
                distance += -scrollWheel * Mathf.Lerp(minDistanceSpeed, maxDistanceSpeed, distance / maxDistance) * zoomSpeed * speedMod;
                distance = Mathf.Clamp( distance, minDistance, maxDistance );
                
                hasChanged = true;
            }

            float xDelta = 0f, yDelta = 0f;
            xDelta += Input.GetAxis( "Horizontal" );
            yDelta += Input.GetAxis( "Vertical" );

            // the right mouse button is down then let's orbit
            if ( Input.GetMouseButton( 0 ) || Input.GetMouseButton( 1 ) )
            {
                xDelta += Input.GetAxis( "Mouse X" );
                yDelta -= Input.GetAxis( "Mouse Y" );
            }

            if ( xDelta != 0f || yDelta != 0f )
            {
                hasChanged = true;

                x += Mathf.Clamp( xDelta, -1f, 1f ) * speed * speedMod;
                y += Mathf.Clamp( yDelta, -1f, 1f ) * speed * speedMod;
            }

            if ( hasChanged )
            {
                SetCamera();
            }

            previousTargetPos = target.position;
        }
    }

    /// <summary>
    /// Sets the script up with the current transform's angles
    /// </summary>
    public void Setup ()
    {
        Vector3 angles = xform.eulerAngles;
        x = angles.y;
        y = angles.x;

        SetCamera();
    }

    /// <summary>
    /// Sets the angles and distance for the object
    /// </summary>
    public void SetOrbitPoint ( float xAngle, float yAngle, float distance )
    {
        x = xAngle;
        y = yAngle;
        this.distance = distance;

        SetCamera();
    }

    /// <summary>
    /// Sets the orbit camera to a particular position and has it look at the target using the given up axis
    /// </summary>
    /// <param name="position">The position to set the camera to</param>
    /// <param name="up">The axis to use at the 'up axis' when looking at the target</param>
    public void SetOrbitPosition ( Vector3 position, Vector3 up )
    {
        xform.position = position;
        xform.LookAt( target.position, up );
        x = xform.localEulerAngles.y;
        y = xform.localEulerAngles.x;
        distance = Vector3.Distance( position, target.position );

        SetCamera();
    }

    /// <summary>
    /// Sets the camera position based on current attributes
    /// </summary>
    void SetCamera ()
    {
        Vector3 targetPos = Vector3.zero;
        if ( target != null ) targetPos = target.position;

        Quaternion rotation = Quaternion.Euler( y, x, 0f );
        Vector3 position = rotation * new Vector3( 0.0f, 0.0f, -distance ) + targetPos;

        xform.rotation = rotation;
        xform.position = position;
    }
}