using UnityEngine;

public class TestRunningWater : MonoBehaviour
{
    public Material addMaterial = null;
    
    public bool addedWater = false;

    void Update()
    {
        if (addMaterial)
        {
            if (!addedWater && Input.GetKeyUp(KeyCode.P))
            {
                addedWater = true;
                MeshRenderer[] meshRenderers = (MeshRenderer[])FindObjectsOfType(typeof(MeshRenderer));
                for (int i = 0; i < meshRenderers.Length; i++)
                {
                    Material[] materials = meshRenderers[i].sharedMaterials;
                    Material[] newMaterials = new Material[materials.Length + 1];
                    materials.CopyTo(newMaterials, 0);
                    newMaterials[materials.Length] = addMaterial;
                    meshRenderers[i].sharedMaterials = newMaterials;
                }

                SkinnedMeshRenderer[] skinnedMeshRenderers = (SkinnedMeshRenderer[])FindObjectsOfType(typeof(SkinnedMeshRenderer));
                for (int i = 0; i < meshRenderers.Length; i++)
                {
                    Material[] materials = skinnedMeshRenderers[i].sharedMaterials;
                    Material[] newMaterials = new Material[materials.Length + 1];
                    materials.CopyTo(newMaterials, 0);
                    newMaterials[materials.Length] = addMaterial;
                    skinnedMeshRenderers[i].sharedMaterials = newMaterials;
                }
            }
            else if (addedWater && Input.GetKeyUp(KeyCode.P))
            {
                addedWater = false;
                MeshRenderer[] meshRenderers = (MeshRenderer[])FindObjectsOfType(typeof(MeshRenderer));
                for (int i = 0; i < meshRenderers.Length; i++)
                {
                    Material[] materials = meshRenderers[i].sharedMaterials;
                    Material[] newMaterials = new Material[materials.Length - 1];
                    System.Array.Copy(materials, 0, newMaterials, 0, newMaterials.Length);
                    meshRenderers[i].sharedMaterials = newMaterials;
                }

                SkinnedMeshRenderer[] skinnedMeshRenderers = (SkinnedMeshRenderer[])FindObjectsOfType(typeof(SkinnedMeshRenderer));
                for (int i = 0; i < meshRenderers.Length; i++)
                {
                    Material[] materials = skinnedMeshRenderers[i].sharedMaterials;
                    Material[] newMaterials = new Material[materials.Length - 1];
                    System.Array.Copy(materials, 0, newMaterials, 0, newMaterials.Length);
                    skinnedMeshRenderers[i].sharedMaterials = newMaterials;
                }
            }
        }
    }
}