using UnityEngine;

[ExecuteInEditMode]
public class FurTextureGenerator : MonoBehaviour
{
	// New
	public enum FurAlgorithm
	{
		SimpleRandNoise
	};	
	public FurAlgorithm furAlgo = FurAlgorithm.SimpleRandNoise;
	public float density = 0.75f;
	public Texture2D furTexture;
	
	
	// Reuse
	public int furTextureWidth = 64;
	public int furTextureHeight = 64;
	
	public bool needFullUpdate = true;
	public bool useSpec = false;
	public bool fastPreview = false;
	public float diffuseIntensity = 1.0f;
	public Color furColor = ColorRGB(188, 158, 118);
	public float specularIntensity = 1.0f;
	
	
	// Old
	public float intensity = 1.0f;
	
	public Color keyColor = ColorRGB(188, 158, 118);
	public Color fillColor = ColorRGB(86, 91, 108);
	public Color backColor = ColorRGB(44, 54, 57);
	public float wrapAround = 0.0f;
	public float metalic = 0.0f;
	
	public float specularShininess = 0.078125f;
	
	public float translucency = 0.0f; // skin
	public Color translucentColor = ColorRGB(255, 82, 82);
	
	
	
	void Awake() 
	{
		if (!furTexture)
		{
			Bake();
		}
	}
	
	private static Color ColorRGB(int r, int g, int b) 
	{
		return new Color((float)r / 255.0f, (float)g / 255.0f, (float)b / 255.0f, 0.0f);
	}
	
	private void CheckConsistency() 
	{
		intensity = Mathf.Max(0.0f, intensity);
	
		wrapAround = Mathf.Clamp(wrapAround, -1.0f, 1.0f);
		metalic = Mathf.Clamp(metalic, 0.0f, 12.0f);
		
		diffuseIntensity = Mathf.Max(0.0f, diffuseIntensity);
		specularIntensity = Mathf.Max(0.0f, specularIntensity);
		specularShininess = Mathf.Clamp(specularShininess, 0.01f, 1.0f);
				
		translucency = Mathf.Clamp01(translucency);
	}	
	
	private void GenerateFurTexture(int width, int height) 
	{
		Texture2D tex;
		if (furTexture && furTexture.width == width && furTexture.height == height)
		{
			tex = furTexture;
		}
		else
		{
			tex = new Texture2D(width, height, TextureFormat.ARGB32, false);
		}
		
		CheckConsistency();
		
		// Only update the random texture on a change in the texture resolution or density change
		if (needFullUpdate)
		{
			needFullUpdate = false;
			FillFurTexture(tex, true);
		}
		else
		{
			FillFurTexture(tex, false);	
		}
		tex.Apply();
		tex.wrapMode = TextureWrapMode.Clamp;
	
		if (furTexture != tex)
		{
			DestroyImmediate(furTexture);
		}
		
		furTexture = tex;
	}

	public void Preview() 
	{
		GenerateFurTexture(32, 32);
	}
	
	public void Bake() 
	{
		GenerateFurTexture(furTextureWidth, furTextureHeight);
	}	
	
	private void FillFurTexture(Texture2D tex, bool fullUpdate)
	{
		switch (furAlgo)
		{
		case FurAlgorithm.SimpleRandNoise:
			if (fullUpdate)
			{
				SimpleRandNoise(tex);
			}
			else
			{
				SimpleRandNoiseUpdate(tex);
			}
			break;
		}
	}		
		
	/// This functions prepares a texture to be used for fur rendering
	/// This will contain the final texture
	/// Hair density in [0..1] range
	private void SimpleRandNoise(Texture2D tex)
	{
	    int totalPixels = furTextureWidth * furTextureHeight;
	 
	    // An array to hold our pixels
	    Color[] colors;
	    colors = new Color[totalPixels];
	 
	    // Initialize all pixels to transparent black
	    for (int i = 0; i < totalPixels; i++)
		{
	        colors[i] = new Color(0.0f, 0.0f, 0.0f, 0.0f);
		}
	    // Compute the number of opaque pixels = number of hair strands
	    int nrStrands = (int)(density * totalPixels);
	 
	    // Fill texture with opaque pixels
	    for (int i = 0; i < nrStrands; i++)
	    {
	        int x, y;
	        // Random position on the texture
	        x = Random.Range(0, furTextureHeight);
	        y = Random.Range(0, furTextureWidth);
	        colors[x * furTextureWidth + y] = GetInspectorColor();
	    }
	 
	    // Sets all the pixels on the texture; this is a little more efficient
		// since we would often be setting the pixel twice if opaque pixel
	    tex.SetPixels(colors);
	}
	
	/// <summary>
	/// Simple update of the random noise texture.
	/// Updates anything *not* having to do with regenerating the noise.
	/// </summary>
	/// <param name='tex'>
	/// Tex.
	/// </param>
	private void SimpleRandNoiseUpdate(Texture2D tex)
	{
		for (int i = 0; i < tex.width; i++)
		{
			for (int j = 0; j < tex.height; j++)
			{
				// Don't touch the pixels that are marked for transparency
				if (tex.GetPixel(i, j).a != 0.0f)
				{
					tex.SetPixel(i, j, GetInspectorColor());
				}
			}
		}
	}
	
	/// <summary>
	/// Gets the color of the inspector.
	/// </summary>
	/// <returns>
	/// The inspector color.
	/// </returns>
	private Color GetInspectorColor()
	{
		return new Color(
				furColor.r * diffuseIntensity, 
				furColor.g * diffuseIntensity,
				furColor.b * diffuseIntensity,
				useSpec? specularIntensity: 1.0f
			);
	}
}