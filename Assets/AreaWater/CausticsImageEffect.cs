using UnityEngine;

namespace OceanToolkit
{
    using VH = VectorHelpers;

    [ExecuteInEditMode]
    [RequireComponent(typeof(Camera))]
    public class CausticsImageEffect : MonoBehaviour
    {
        [SerializeField] protected Material mat;
        [SerializeField] protected Light sun;

        [SerializeField] protected float patternAngle0 = 0.0f;
        [SerializeField] protected float patternAngle1 = 100.0f;
        [SerializeField] protected float patternSpeed0 = 1.0f;
        [SerializeField] protected float patternSpeed1 = 0.5f;
        protected Vector2 patternOffset0 = Vector2.zero;
        protected Vector2 patternOffset1 = Vector2.zero;

        protected Camera cam;

        public Material CausticsMaterial
        {
            get { return mat; }
            set { mat = value; }
        }

        public Light SunLight
        {
            get { return sun; }
            set { sun = value; }
        }

        public float PatternAngle0
        {
            get { return patternAngle0; }
            set { patternAngle0 = Mathf.Clamp(value, 0.0f, 360.0f); }
        }
        public float PatternAngle1
        {
            get { return patternAngle1; }
            set { patternAngle1 = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float PatternSpeed0
        {
            get { return patternSpeed0; }
            set { patternSpeed0 = Mathf.Max(0.0f, value); }
        }
        public float PatternSpeed1
        {
            get { return patternSpeed1; }
            set { patternSpeed1 = Mathf.Max(0.0f, value); }
        }

        private Transform myCameraTransform;
        public Transform cameraTransform
        {
            get
            {
                if (myCameraTransform == null)
                {
                    myCameraTransform = cam.transform;
                }

                return myCameraTransform;
            }
        }

        public float m_FogDensity = 0.25f;
        public float FogDensity
        {
            get
            {
                return m_FogDensity;
            }
            set {
                m_FogDensity = value;
            }
        }

        public Color m_FogColor = new Color32(46, 124, 150, 255);
        public Color FogColor
        {
            get
            {
                return m_FogColor;
            }
            set
            {
                m_FogColor = value;
            }
        }

        private float m_FogStart = 0.0f;
        public float FogStart
        {
            get
            {
                return m_FogStart;
            }
            set
            {
                m_FogStart = value;
            }
        }

        public float m_FogEnd = 15f;
        public float FogEnd
        {
            get
            {
                return m_FogEnd;
            }
            set
            {
                m_FogEnd = value;
            }
        }

        public float m_WaterLevel = 2;
        [SerializeField]
        public float WaterLevel
        {
            get
            {
                return m_WaterLevel;
            }
            set
            {
                m_WaterLevel = value;
            }
        }

        private float m_causticSacle = 5;
        public float CausticSacle
        {
            get
            {
                return m_causticSacle;
            }
            set
            {
                m_causticSacle = value;
            }
        }

        private float m_causticStrength = 0.075f;
        public float CausticStrength
        {
            get
            {
                return m_causticStrength;
            }
            set
            {
                m_causticStrength = value;
            }
        }

        private float m_causeticDepth = 2;
        public float CauseticDepth
        {
            get
            {
                return m_causeticDepth;
            }
            set
            {
                m_causeticDepth = value;
            }
        }

        public void Start()
        {
            cam = GetComponent<Camera>();
        }

        protected void UpdateParams()
        {
            float pAngle0 = patternAngle0 * Mathf.Deg2Rad;
            float pAngle1 = patternAngle1 * Mathf.Deg2Rad;
            patternOffset0 += new Vector2(Mathf.Cos(pAngle0), Mathf.Sin(pAngle0)) * patternSpeed0 * Time.deltaTime;
            patternOffset1 += new Vector2(Mathf.Cos(pAngle1), Mathf.Sin(pAngle1)) * patternSpeed1 * Time.deltaTime;
        }

        protected void SendParamsToShader()
        {
            if (mat == null || !mat.HasProperty("ot_Pattern0"))
            {
                return;
            }

            // Texture animations
            Vector2 patternScale0 = mat.GetTextureScale("ot_Pattern0");
            Vector2 patternScale1 = mat.GetTextureScale("ot_Pattern1");

            mat.SetTextureOffset("ot_Pattern0", VH.Mul(patternOffset0, patternScale0));
            mat.SetTextureOffset("ot_Pattern1", VH.Mul(patternOffset1, patternScale1));

            // World-space up vector in view-space
            Shader.SetGlobalVector("ot_ViewSpaceUpDir", cam.worldToCameraMatrix.MultiplyVector(Vector3.up));

            // Light direction in view-space
            Vector3 lightDir = Vector3.up;

            if (sun != null)
            {
                lightDir = -sun.transform.forward;
            }

            float zenithScalar = Mathf.Max(0.0f, Vector3.Dot(lightDir, Vector3.up));
            Shader.SetGlobalFloat("ot_ZenithScalar", zenithScalar);

            // Inverse view projection matrix
            Matrix4x4 invViewProjection = (cam.projectionMatrix * cam.worldToCameraMatrix).inverse;
            Shader.SetGlobalMatrix("ot_InvViewProj", invViewProjection);

            Matrix4x4 frustumCorners = Matrix4x4.identity;

            float fov = cam.fieldOfView;
            float near = cam.nearClipPlane;
            float aspect = cam.aspect;

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;
            Vector3 toTop = cameraTransform.up * halfHeight;

            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;

            topLeft.Normalize();
            topLeft *= scale;

            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            mat.SetMatrix("_FrustumCornersRay", frustumCorners);

            mat.SetFloat("_FogDensity", m_FogDensity);
            mat.SetColor("_FogColor", m_FogColor);
            mat.SetFloat("_FogStart", m_FogStart);
            mat.SetFloat("_FogEnd", m_FogEnd);
            mat.SetFloat("_WaterLevel", m_WaterLevel);
            mat.SetFloat("_MaxDepth", m_causeticDepth);
            mat.SetFloat("_CausticsStrength",m_causticStrength);
        }

        public void Update()
        {
            UpdateParams();
        }

        [ImageEffectOpaque]
        public void OnRenderImage(RenderTexture src, RenderTexture dst)
        {
            SendParamsToShader();

            if (mat != null)
            {
                Graphics.Blit(src, dst, mat);
            }
            else
            {
                Graphics.Blit(src, dst);
            }
        }
    }
}