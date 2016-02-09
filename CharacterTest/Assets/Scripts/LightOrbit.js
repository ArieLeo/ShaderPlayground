var target : Transform;
var distance = 10.0;

var xSpeed = 250.0;
var ySpeed = 120.0;

var yMinLimit = -20;
var yMaxLimit = 80;
var multiplier = 1.0;
var intensities = new Array();

private var x = 0.0;
private var y = 0.0;
private var childLights : Component[];

function Start () 
{
    var angles = transform.eulerAngles;
    x = angles.y;
    y = angles.x;

	// Make the rigid body not change rotation
   	if (rigidbody)
		rigidbody.freezeRotation = true;
		
	childLights = GetComponentsInChildren(Light);
	
	var count = 0;
	for (var curLight : Light in childLights) 
	{
	    intensities.push(curLight.intensity);
	    count++;
	}
}

function Update() 
{
	var count = 0;
	for (var curLight : Light in childLights) 
	{
	    curLight.intensity = intensities[count] * multiplier;
	    count++;
	}
}

function LateUpdate () {
    if (target && Input.GetMouseButton(0)) {
        x += Input.GetAxis("Mouse X") * xSpeed * 0.02;
        y += Input.GetAxis("Mouse Y") * ySpeed * 0.02;
 		
 		y = ClampAngle(y, yMinLimit, yMaxLimit);
 		       
        var rotation = Quaternion.Euler(y, x, 0);

        
        transform.rotation = rotation;

    }
}

static function ClampAngle (angle : float, min : float, max : float) {
	if (angle < -360)
		angle += 360;
	if (angle > 360)
		angle -= 360;
	return Mathf.Clamp (angle, min, max);
}