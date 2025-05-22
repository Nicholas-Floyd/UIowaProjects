using UnityEngine;

namespace Xyro.CircuitSimXR.Nick
{
    [RequireComponent(typeof(MeshRenderer))]
    public class DiodeBehavior : MonoBehaviour
    {
        [SerializeField] private Material diodeUnlitMaterial;
        [SerializeField] private Material diodeLitMaterial;

        public void SetLitState(bool lit)
        {
            MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
            Material[] mats = meshRenderer.materials;

            mats[1] = lit ? diodeLitMaterial : diodeUnlitMaterial;
            meshRenderer.materials = mats;

            Debug.Log($"[Diode] Lit state set to: {lit}");
        }

        public void SetUnlitState(bool unlit)
        {
            MeshRenderer meshRenderer = GetComponent<MeshRenderer>();
            Material[] mats = meshRenderer.materials;

            mats[1] = unlit ? diodeUnlitMaterial : diodeLitMaterial;
            meshRenderer.materials = mats;

            Debug.Log($"[Diode] Unlit state set to: {unlit}");
        }

    }
}
