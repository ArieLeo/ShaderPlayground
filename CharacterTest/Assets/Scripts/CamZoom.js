var zoomSpeed = 250;

var zoomMin = 30;
var zoomMax = 80;

function LateUpdate (){
	
    if (Input.GetMouseButton(2)) {
		 camera.fieldOfView -= Input.GetAxis("Mouse Y") * zoomSpeed * 0.01;
		 
		 camera.fieldOfView = Mathf.Clamp(camera.fieldOfView, zoomMin, zoomMax);
		 
    }
}