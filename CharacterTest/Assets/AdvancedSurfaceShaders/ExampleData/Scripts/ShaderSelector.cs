using UnityEngine;
using System.Collections;

public class ShaderSelector : MonoBehaviour
{
    public Renderer objectRenderer = null;

    public Light directionalLight;

    public Rotate[] toggleRotateScripts;

    public bool infoShowing = true;

    public bool lightsPaused = true;

    private AdvancedSS.AdvancedShader advancedShader = null;

    void Awake()
    {
        foreach (Rotate rotateScript in toggleRotateScripts)
        {
            rotateScript.enabled = !lightsPaused;
        }
    }

    void OnEnable()
    {
        advancedShader = new AdvancedSS.AdvancedShader();
    }

    void Update()
    {
        if (Input.GetKeyUp(KeyCode.P))
        {
            lightsPaused = !lightsPaused;

            foreach (Rotate rotateScript in toggleRotateScripts)
            {
                rotateScript.enabled = !lightsPaused;
            }
        }

        if (Input.GetKeyUp(KeyCode.O))
        {
            Screen.showCursor = !Screen.showCursor;
        }

        if (Input.GetKeyUp(KeyCode.Tab))
        {
            infoShowing = !infoShowing;
        }
    }

    void OnGUI()
    {
        if (infoShowing)
        {
            GUILayout.Label("Press P key to toggle light movement");
            GUILayout.Label("Click and drag or use arrow keys to orbit camera");
            GUILayout.Label("Zoom with the mouse scrollwheel");
            GUILayout.Label("Press O key to toggle mouse cursor display");
            GUILayout.Label("\nPress Tab to toggle this information\n");

            GUILayout.Space(20f);

            // Shader Params
            bool toggle = false;
            bool somethingChanged = false;
            AdvancedSS.AdvancedShader.ShaderEffect[] shaderEffects = (AdvancedSS.AdvancedShader.ShaderEffect[])System.Enum.GetValues(typeof(AdvancedSS.AdvancedShader.ShaderEffect));
            for (int i = 0; i < shaderEffects.Length; i++)
			{
                toggle = advancedShader.HasEffect(shaderEffects[i]);
                bool newToggle = GUILayout.Toggle(toggle, shaderEffects[i].ToString());
                if (toggle != newToggle)
                {
                    somethingChanged = true;
                    if (newToggle) advancedShader.shaderEffects.Add(shaderEffects[i]);
                    else advancedShader.shaderEffects.Remove(shaderEffects[i]);
                }
			}

            if (somethingChanged)
            {
                if (Shader.Find(advancedShader.ShaderName()) == null)
                {
                    GUILayout.Space(20f);
                    GUILayout.Label("That effect combination is a built-in shader");
                }
                else
                {
                    objectRenderer.material.shader = Shader.Find(advancedShader.ShaderName());
                }
            }
        }
    }
}
