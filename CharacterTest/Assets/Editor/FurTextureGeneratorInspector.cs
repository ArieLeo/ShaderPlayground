using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(FurTextureGenerator))]
internal class FurTextureGeneratorInspector : Editor
{
	private bool changed = false;
	private bool previewRGB = true;
	
	private static string kDirectoryName = "Assets/GeneratedTextures";
	private static string kExtensionName = "png";
	private static string kFurTexturePropertyName = "_FurTex";
	
	private static int kTexturePreviewBorder = 8;
	private static string[] kTextureSizes = { "16", "32", "64", "128", "256" };
	private static int[] kTextureSizesValues = { 16, 32, 64, 128, 256 };
	

	private static Texture2D PersistFurTexture(string assetName, Texture2D tex)
	{
		if (!System.IO.Directory.Exists(kDirectoryName))
		{
			System.IO.Directory.CreateDirectory(kDirectoryName);	
		}

		string assetPath = System.IO.Path.Combine(kDirectoryName, assetName + "." + kExtensionName);
		bool newAsset = !System.IO.File.Exists(assetPath);
		
		System.IO.File.WriteAllBytes(assetPath, tex.EncodeToPNG());
		AssetDatabase.ImportAsset(assetPath, ImportAssetOptions.ForceUpdate);

		TextureImporter texSettings = AssetImporter.GetAtPath(assetPath) as TextureImporter;
		if (!texSettings)
		{
			// Workaround for bug when importing first generated texture in the project
			AssetDatabase.Refresh();
			AssetDatabase.ImportAsset(assetPath, ImportAssetOptions.ForceUpdate);
			texSettings = AssetImporter.GetAtPath(assetPath) as TextureImporter;
		}
		texSettings.textureFormat = TextureImporterFormat.AutomaticTruecolor;
		texSettings.wrapMode = TextureWrapMode.Clamp;
		if (newAsset)
		{
			AssetDatabase.ImportAsset(assetPath, ImportAssetOptions.ForceUpdate);
		}
		
		AssetDatabase.Refresh();
		
		Texture2D newTex = AssetDatabase.LoadAssetAtPath(assetPath, typeof(Texture2D)) as Texture2D;		
		return newTex;
	}
	
	private void PersistFurTexture()
	{
		FurTextureGenerator furGen = target as FurTextureGenerator;
		if (!furGen) return;
		
		Material m = FindCompatibleMaterial(furGen);
		
		string assetName = (m ? m.name : furGen.gameObject.name) + kFurTexturePropertyName;
		Texture2D persistentTexture = PersistFurTexture(assetName, furGen.furTexture);
		
		if (m)
		{
			m.SetTexture(kFurTexturePropertyName, persistentTexture);
		}
	}
	
	/// <summary>
	/// Finds the compatible material based of if the gameobject already has a .
	/// </summary>
	/// <returns>
	/// The compatible material.
	/// </returns>
	/// <param name='furGen'>
	/// The fur texture generator
	/// </param>
	static Material FindCompatibleMaterial(FurTextureGenerator furGen)
	{
		Renderer r = furGen.gameObject.renderer;
		if (!r)
		{
			return null;
		}
		
		Material m = r.sharedMaterial;
		if (m && m.HasProperty(kFurTexturePropertyName))
		{
			return m;
		}
		
		return null;
	}

	public void OnEnable()
	{
		FurTextureGenerator furGen = target as FurTextureGenerator;
		if (!furGen) return;
		
		string path = AssetDatabase.GetAssetPath(furGen.furTexture);
		if (path == "")
		{
			changed = true;
		}
	}
	
	public void OnDisable()
	{
		// Access to AssetDatabase from OnDisable/OnDestroy results in a crash
		// otherwise would be nice to bake fur texture when leaving asset
	}

	public override void OnInspectorGUI()
	{
		FurTextureGenerator furGen = target as FurTextureGenerator;
		
		float oldDensity = furGen.density;
		int oldWidth = furGen.furTextureWidth;
		int oldHeight = furGen.furTextureHeight;

		furGen.density = EditorGUILayout.Slider("Density", furGen.density, 0f, 3f);

		EditorGUILayout.Space();
		furGen.diffuseIntensity = EditorGUILayout.Slider("Diffuse", furGen.diffuseIntensity, 0f, 2f);
		if (furGen.diffuseIntensity > 1e-6)
		{
			EditorGUI.indentLevel++;

			furGen.furColor = EditorGUILayout.ColorField("Fur Color", furGen.furColor);

			EditorGUI.indentLevel--;
		}
           
		EditorGUILayout.Space();
		furGen.useSpec = EditorGUILayout.Toggle("Use Spec?", furGen.useSpec);
		if (furGen.useSpec)
		{
			EditorGUI.indentLevel++;
			
			GUILayout.Label("Warning: a low spec value might be clipped during alpha-test.");
			furGen.specularIntensity = EditorGUILayout.Slider("Specular", furGen.specularIntensity, 0.1f, 1f);
			
			EditorGUI.indentLevel--;
		}		
		
		EditorGUILayout.Space();
		GUILayout.BeginHorizontal();
		EditorGUILayout.PrefixLabel("Fur Texture", "MiniPopup");
		furGen.furTextureWidth = EditorGUILayout.IntPopup(furGen.furTextureWidth, kTextureSizes, kTextureSizesValues, GUILayout.MinWidth(40));
		GUILayout.Label("x");
		furGen.furTextureHeight = EditorGUILayout.IntPopup(furGen.furTextureHeight, kTextureSizes, kTextureSizesValues, GUILayout.MinWidth(40));
		GUILayout.FlexibleSpace();
		GUILayout.EndHorizontal();
		
		if (oldWidth != furGen.furTextureWidth || oldHeight != furGen.furTextureHeight || oldDensity != furGen.density)
		{
			 furGen.needFullUpdate = true;
		}
		
		if (GUI.changed)
		{
			Undo.RegisterUndo(furGen, "FurTexture Params Change");
			changed = true;
		}
				
		// Preview
		GUILayout.BeginHorizontal();
		furGen.fastPreview = EditorGUILayout.Toggle ("Fast Preview", furGen.fastPreview);
		GUILayout.FlexibleSpace();
		if (GUILayout.Button(previewRGB? "RGB": "Alpha", "MiniButton", GUILayout.MinWidth(38)))
		{
			previewRGB = !previewRGB;
		}
		GUILayout.EndHorizontal();
		
		if (changed || !furGen.furTexture)
		{
			GUILayout.BeginHorizontal();
			GUILayout.FlexibleSpace();
			if (GUILayout.Button("Bake", GUILayout.MinWidth(64)))
			{
				furGen.Bake();
				PersistFurTexture();
				changed = false;
			}
			else
			{
				if (furGen.fastPreview)
					furGen.Preview();
				else
					furGen.Bake();
			}
			GUILayout.EndHorizontal();
		}
		
		Rect r = GUILayoutUtility.GetAspectRect(1.0f);
		r.x += kTexturePreviewBorder;
		r.y += kTexturePreviewBorder;
		r.width -= kTexturePreviewBorder * 2;
		r.height -= kTexturePreviewBorder * 2;
		if (previewRGB)
		{
			EditorGUI.DrawPreviewTexture(r, furGen.furTexture);
		}
		else
		{
			EditorGUI.DrawTextureAlpha(r, furGen.furTexture);
		}

		// save preview to disk
		if (GUI.changed && changed && furGen.furTexture && furGen.fastPreview)
		{
			PersistFurTexture();
		}
	}
	
}