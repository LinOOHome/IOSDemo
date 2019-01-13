using UnityEngine;

namespace OceanToolkit
{
    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class OceanCamera : MonoBehaviour
    {
        protected Camera cam;
        public CausticsImageEffect caustics;

        public void Start()
        {
            cam = GetComponent<Camera>();
            //cam.depthTextureMode |= DepthTextureMode.Depth;
        }

        void OnGUI()
        {
            //if (GUI.Button(new Rect(Screen.width - 200, 200, 100, 100), "Caustics"))
            //{
            //    caustics.enabled = !caustics.enabled;
            //}
        }
    }
}