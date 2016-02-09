using UnityEngine;
using System.Collections;

public class SwapHeadMaterials : MonoBehaviour
{
    //public      Material            sssMaterial;
    //public      Material            bumpSpecMaterial;

    //public      Renderer            headRenderer;

    public      Light               directionalLight;

    public      Rotate[]            toggleRotateScripts;

    //public      bool                sssMaterialShowing = true;

    public      bool                infoShowing = true;

    public      bool                lightsPaused = true;

    void Awake ()
    {
        foreach ( Rotate rotateScript in toggleRotateScripts )
        {
            rotateScript.enabled = !lightsPaused;
        }
    }

    void Update ()
    {
        //if ( !sssMaterial || !bumpSpecMaterial || !headRenderer )
        //{
        //    return;
        //}

        //if ( Input.GetKeyUp( KeyCode.M ) )
        //{
        //    sssMaterialShowing = !sssMaterialShowing;
        //    headRenderer.material = ( sssMaterialShowing ) ? sssMaterial : bumpSpecMaterial;
        //}

        if ( Input.GetKeyUp( KeyCode.P ) )
        {
            lightsPaused = !lightsPaused;

            foreach ( Rotate rotateScript in toggleRotateScripts )
            {
                rotateScript.enabled = !lightsPaused;
            }
        }

        if ( Input.GetKeyUp( KeyCode.O ) )
        {
            Screen.showCursor = !Screen.showCursor;
        }

        if ( Input.GetKeyUp( KeyCode.Tab ) )
        {
            infoShowing = !infoShowing;
        }
    }

    void OnGUI ()
    {
        //if ( !sssMaterial || !bumpSpecMaterial || !headRenderer )
        //{
        //    return;
        //}

        if ( infoShowing )
        {

            //if ( sssMaterialShowing )
            //{
            //    GUILayout.Label( "Press M key to switch to Bump Specular material" );
            //}
            //else
            //{
            //    GUILayout.Label( "Press M key to switch to Skin Shader material" );
            //}

            GUILayout.Label( "Press P key to toggle light movement" );
            GUILayout.Label( "Click and drag or use arrow keys to orbit camera around the head" );
            GUILayout.Label( "Zoom with the mouse scrollwheel" );
            GUILayout.Label( "Press O key to toggle mouse cursor display" );
            GUILayout.Label( "\nPress Tab to toggle this information\n" );
        }
    }
}
