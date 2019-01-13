using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using VH = OceanToolkit.VectorHelpers;

namespace VoxelTerrainCore.Water
{
    public class MobileWaterComponent : MonoBehaviour
    {
        protected static bool DebugMode = false;

        public float Level;

        [SerializeField]
        protected Material mat;
        [SerializeField]
        protected Material underMat;
        [SerializeField]
        protected Light sun;

        public enum RelectionType
        {
            Off,
            Sky,
            SkyAndObjects
        }
        public RelectionType reflectionType = RelectionType.Off;

        [SerializeField]
        protected float windAngle = 0.0f;
        [SerializeField]
        protected Vector4 waveAngles = new Vector4(0.0f, 17.0f, 0.0f, 0.0f);
        [SerializeField]
        protected Vector4 waveSpeeds = new Vector4(1.0f, 3.0f, 0.0f, 0.0f);
        [SerializeField]
        protected Vector4 waveScales = new Vector4(0.0f, 0.2f, 0.0f, 0.0f);
        [SerializeField]
        protected Vector4 waveLengths = new Vector4(8.0f, 30.0f, 10.0f, 10.0f);
        [SerializeField]
        protected Vector4 waveExponents = new Vector4(1.0f, 4.0f, 1.0f, 1.0f);
        protected Vector4 waveOffsets = Vector4.zero;
        protected Vector4 waveDirection01 = Vector4.zero;
        protected Vector4 waveDirection23 = Vector4.zero;
        protected Vector4 waveConstants = Vector4.zero;
        protected Vector4 waveDerivativeConstants = Vector4.zero;

        [SerializeField]
        protected float normalMapAngle0 = 0.0f;
        [SerializeField]
        protected float normalMapAngle1 = 36.0f;
        [SerializeField]
        protected float normalMapSpeed0 = 0.5f;
        [SerializeField]
        protected float normalMapSpeed1 = 0.3f;
        protected Vector2 normalMapOffset0 = Vector2.zero;
        protected Vector2 normalMapOffset1 = Vector2.zero;

        [SerializeField]
        protected float foamMapAngle = 180.0f;
        [SerializeField]
        protected float foamMapSpeed = 0.05f;
        protected Vector2 foamMapOffset = Vector2.zero;

        [SerializeField]
        protected bool mainCameraOnly = false;
        [SerializeField]
        protected bool sceneCameraFixFarPlane = true;
        [SerializeField]
        protected float sceneCameraFarPlane = 1000.0f;

        [SerializeField]
        public MeshFilter underMeshFilter;

        protected float position;
        protected float scaleSum;

        public float farPlaneDuringRendering;

        [SerializeField]
        public float specularRoughness = 0.0002f;
        [SerializeField]
        public float specularIntensity = 0.02f;
        [SerializeField]
        public float foamFalloff = 0.5f;
        [SerializeField]
        public float relectionStrength = 0.9f;
        [SerializeField]
        public float relectionNormalOffset = 0.1f;

        public float foamStrength = 0.5f;

        public Material OceanMaterial
        {
            get { return mat; }
            set { mat = value; }
        }

        public Material UnderMaterial
        {
            get { return underMat; }
            set { underMat = value; }
        }

        public Light SunLight
        {
            get { return sun; }
            set { sun = value; }
        }

        public float WindAngle
        {
            get { return windAngle; }
            set { windAngle = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float WaveAngle0
        {
            get { return waveAngles.x; }
            set { waveAngles.x = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float WaveAngle1
        {
            get { return waveAngles.y; }
            set { waveAngles.y = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float WaveAngle2
        {
            get { return waveAngles.z; }
            set { waveAngles.z = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float WaveAngle3
        {
            get { return waveAngles.w; }
            set { waveAngles.w = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float WaveSpeed0
        {
            get { return waveSpeeds.x; }
            set { waveSpeeds.x = Mathf.Max(0.0f, value); }
        }

        public float WaveSpeed1
        {
            get { return waveSpeeds.y; }
            set { waveSpeeds.y = Mathf.Max(0.0f, value); }
        }

        public float WaveSpeed2
        {
            get { return waveSpeeds.z; }
            set { waveSpeeds.z = Mathf.Max(0.0f, value); }
        }

        public float WaveSpeed3
        {
            get { return waveSpeeds.w; }
            set { waveSpeeds.w = Mathf.Max(0.0f, value); }
        }

        public float WaveScale0
        {
            get { return waveScales.x; }
            set { waveScales.x = Mathf.Max(0.0f, value); }
        }

        public float WaveScale1
        {
            get { return waveScales.y; }
            set { waveScales.y = Mathf.Max(0.0f, value); }
        }

        public float WaveScale2
        {
            get { return waveScales.z; }
            set { waveScales.z = Mathf.Max(0.0f, value); }
        }

        public float WaveScale3
        {
            get { return waveScales.w; }
            set { waveScales.w = Mathf.Max(0.0f, value); }
        }

        public float WaveLength0
        {
            get { return waveLengths.x; }
            set { waveLengths.x = Mathf.Max(Mathf.Epsilon, value); }
        }

        public float WaveLength1
        {
            get { return waveLengths.y; }
            set { waveLengths.y = Mathf.Max(Mathf.Epsilon, value); }
        }

        public float WaveLength2
        {
            get { return waveLengths.z; }
            set { waveLengths.z = Mathf.Max(Mathf.Epsilon, value); }
        }

        public float WaveLength3
        {
            get { return waveLengths.w; }
            set { waveLengths.w = Mathf.Max(Mathf.Epsilon, value); }
        }

        public float WaveSharpness0
        {
            get { return waveExponents.x; }
            set { waveExponents.x = Mathf.Max(1.0f, value); }
        }

        public float WaveSharpness1
        {
            get { return waveExponents.y; }
            set { waveExponents.y = Mathf.Max(1.0f, value); }
        }

        public float WaveSharpness2
        {
            get { return waveExponents.z; }
            set { waveExponents.z = Mathf.Max(1.0f, value); }
        }

        public float WaveSharpness3
        {
            get { return waveExponents.w; }
            set { waveExponents.w = Mathf.Max(1.0f, value); }
        }

        public float NormalMapAngle0
        {
            get { return normalMapAngle0; }
            set { normalMapAngle0 = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float NormalMapAngle1
        {
            get { return normalMapAngle1; }
            set { normalMapAngle1 = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float NormalMapSpeed0
        {
            get { return normalMapSpeed0; }
            set { normalMapSpeed0 = Mathf.Max(0.0f, value); }
        }

        public float NormalMapSpeed1
        {
            get { return normalMapSpeed1; }
            set { normalMapSpeed1 = Mathf.Max(0.0f, value); }
        }

        public float FoamMapAngle
        {
            get { return foamMapAngle; }
            set { foamMapAngle = Mathf.Clamp(value, 0.0f, 360.0f); }
        }

        public float FoamMapSpeed
        {
            get { return foamMapSpeed; }
            set { foamMapSpeed = Mathf.Max(0.0f, value); }
        }

        public bool MainCameraOnly
        {
            get { return mainCameraOnly; }
            set { mainCameraOnly = value; }
        }

        public bool SceneCameraFixFarPlane
        {
            get { return sceneCameraFixFarPlane; }
            set { sceneCameraFixFarPlane = value; }
        }

        public float SceneCameraFarPlane
        {
            get { return sceneCameraFarPlane; }
            set { sceneCameraFarPlane = Mathf.Max(0.0f, value); }
        }


        public Color deepWaterColor;
        public Color DeepWaterColor
        {
            get { return deepWaterColor; }
            set { deepWaterColor = value; }
        }

        public float fogEnd;
        public float FogEnd
        {
            get { return fogEnd; }
            set { fogEnd = value; }
        }

        public float fogDensity;
        public float FogDensity
        {
            get { return fogDensity; }
            set { fogDensity = value; }
        }

        public Color fogColor;
        public Color FogColor
        {
            get { return fogColor; }
            set { fogColor = value; }
        }

        protected void IntersectFrustumEdgeWaterPlane(Vector3 start, Vector3 end, IList<Vector3> points)
        {
            Plane topPlane = new Plane(Vector3.up, Vector3.up * (position + scaleSum));
            Plane bottomPlane = new Plane(Vector3.up, Vector3.up * position);

            Vector3 delta = end - start;
            Vector3 direction = delta.normalized;
            float length = delta.magnitude;

            float distance;

            if (topPlane.Raycast(new Ray(start, direction), out distance))
            {
                if (distance <= length)
                {
                    Vector3 hit = start + direction * distance;

                    points.Add(new Vector3(hit.x, position, hit.z));
                }
            }

            if (bottomPlane.Raycast(new Ray(start, direction), out distance))
            {
                if (distance <= length)
                {
                    Vector3 hit = start + direction * distance;

                    points.Add(new Vector3(hit.x, position, hit.z));
                }
            }
        }

        protected void IntersectFrustumWaterPlane(Camera cam, out IList<Vector3> points)
        {
            Vector3[] corners = new Vector3[8];

            corners[0] = cam.ViewportToWorldPoint(new Vector3(0.0f, 0.0f, cam.nearClipPlane));
            corners[1] = cam.ViewportToWorldPoint(new Vector3(0.0f, 1.0f, cam.nearClipPlane));
            corners[2] = cam.ViewportToWorldPoint(new Vector3(1.0f, 1.0f, cam.nearClipPlane));
            corners[3] = cam.ViewportToWorldPoint(new Vector3(1.0f, 0.0f, cam.nearClipPlane));

            corners[4] = cam.ViewportToWorldPoint(new Vector3(0.0f, 0.0f, cam.farClipPlane));
            corners[5] = cam.ViewportToWorldPoint(new Vector3(0.0f, 1.0f, cam.farClipPlane));
            corners[6] = cam.ViewportToWorldPoint(new Vector3(1.0f, 1.0f, cam.farClipPlane));
            corners[7] = cam.ViewportToWorldPoint(new Vector3(1.0f, 0.0f, cam.farClipPlane));

            points = new List<Vector3>();

            IntersectFrustumEdgeWaterPlane(corners[0], corners[1], points);
            IntersectFrustumEdgeWaterPlane(corners[1], corners[2], points);
            IntersectFrustumEdgeWaterPlane(corners[2], corners[3], points);
            IntersectFrustumEdgeWaterPlane(corners[3], corners[0], points);

            IntersectFrustumEdgeWaterPlane(corners[4], corners[5], points);
            IntersectFrustumEdgeWaterPlane(corners[5], corners[6], points);
            IntersectFrustumEdgeWaterPlane(corners[6], corners[7], points);
            IntersectFrustumEdgeWaterPlane(corners[7], corners[4], points);

            IntersectFrustumEdgeWaterPlane(corners[0], corners[4], points);
            IntersectFrustumEdgeWaterPlane(corners[1], corners[5], points);
            IntersectFrustumEdgeWaterPlane(corners[2], corners[6], points);
            IntersectFrustumEdgeWaterPlane(corners[3], corners[7], points);
        }

        protected static Vector3[] ProjectPointsToNdc(Matrix4x4 viewProj, IList<Vector3> points)
        {
            Vector3[] ndcPoints = new Vector3[points.Count];

            for (int i = 0; i < points.Count; i++)
            {
                ndcPoints[i] = viewProj.MultiplyPoint(points[i]);
            }

            return ndcPoints;
        }

        protected static Matrix4x4 MapNdcBoundingBoxToFullscreen(Vector3[] ndcPoints)
        {
            // Find ndc bounding box
            Vector3 min = ndcPoints[0];
            Vector3 max = ndcPoints[0];

            for (int i = 1; i < ndcPoints.Length; i++)
            {
                min = Vector3.Min(min, ndcPoints[i]);
                max = Vector3.Max(max, ndcPoints[i]);
            }

            Vector2 size = max - min;

            // Create range matrix so that all points in the bounding box are mapped to [0,1]
            Matrix4x4 range = new Matrix4x4();

            range.m00 = 1.0f / size.x;
            range.m10 = 0.0f;
            range.m20 = 0.0f;
            range.m30 = 0.0f;

            range.m01 = 0.0f;
            range.m11 = 1.0f / size.y;
            range.m21 = 0.0f;
            range.m31 = 0.0f;

            range.m02 = 0.0f;
            range.m12 = 0.0f;
            range.m22 = 1.0f;
            range.m32 = 0.0f;

            range.m03 = -(min.x / size.x);
            range.m13 = -(min.y / size.y);
            range.m23 = 0.0f;
            range.m33 = 1.0f;

            return range;
        }

        protected void UpdateParams()
        {
            position = transform.position.y;
            scaleSum = VH.Sum(waveScales);

            // Update wave function animation
            Vector4 wAngle = (Vector4.one * windAngle + waveAngles) * Mathf.Deg2Rad;
            waveDirection01 = new Vector4(Mathf.Cos(wAngle.x), Mathf.Sin(wAngle.x), Mathf.Cos(wAngle.y), Mathf.Sin(wAngle.y));
            waveDirection23 = new Vector4(Mathf.Cos(wAngle.z), Mathf.Sin(wAngle.z), Mathf.Cos(wAngle.w), Mathf.Sin(wAngle.w));
            waveOffsets += waveSpeeds * Time.deltaTime;
            waveConstants = VH.Div(Vector4.one * (2.0f * Mathf.PI), waveLengths);
            waveDerivativeConstants = 0.5f * VH.Mul(VH.Mul(waveScales, waveConstants), waveExponents);

            // Update texture animations
            float nAngle0 = (windAngle + normalMapAngle0) * Mathf.Deg2Rad;
            float nAngle1 = (windAngle + normalMapAngle1) * Mathf.Deg2Rad;
            normalMapOffset0 += new Vector2(Mathf.Cos(nAngle0), Mathf.Sin(nAngle0)) * normalMapSpeed0 * Time.deltaTime;
            normalMapOffset1 += new Vector2(Mathf.Cos(nAngle1), Mathf.Sin(nAngle1)) * normalMapSpeed1 * Time.deltaTime;

            float fAngle = (windAngle + foamMapAngle) * Mathf.Deg2Rad;
            foamMapOffset += new Vector2(Mathf.Cos(fAngle), Mathf.Sin(fAngle)) * foamMapSpeed * Time.deltaTime;
        }

        protected void SendParamsToShader()
        {
            if (mat == null || !mat.HasProperty("_NormalMap0"))
            {
                return;
            }

            mat.SetFloat("_OceanPosition", position);

            // Wave function animation
            mat.SetVector("_WaveScales", waveScales);
            mat.SetVector("_WaveLengths", waveLengths);
            mat.SetVector("_WaveExponents", waveExponents);
            mat.SetVector("_WaveOffsets", waveOffsets);
            mat.SetVector("_WaveDirection01", waveDirection01);
            mat.SetVector("_WaveDirection23", waveDirection23);
            mat.SetVector("_WaveConstants", waveConstants);
            mat.SetVector("_WaveDerivativeConstants", waveDerivativeConstants);

            // Texture animations
            Vector2 normalMapScale0 = mat.GetTextureScale("_NormalMap0");
            Vector2 normalMapScale1 = mat.GetTextureScale("_NormalMap1");
            Vector2 foamMapScale = mat.GetTextureScale("_FoamMap");

            mat.SetTextureOffset("_NormalMap0", VH.Mul(normalMapOffset0, normalMapScale0));
            mat.SetTextureOffset("_NormalMap1", VH.Mul(normalMapOffset1, normalMapScale1));
            mat.SetTextureOffset("_FoamMap", VH.Mul(foamMapOffset, foamMapScale));
            mat.SetColor("_DeepWaterColorUnlit", deepWaterColor);
            mat.SetFloat("_FoamFalloff", foamFalloff);
            mat.SetFloat("_FoamStrength", foamStrength);
            mat.SetFloat("_RefrNormalOffset", relectionNormalOffset);

            switch (reflectionType)
            {
                case RelectionType.Off:
                    {
                        mat.EnableKeyword("_REFL_OFF");
                        mat.DisableKeyword("_REFL_SKY_ONLY");
                        mat.DisableKeyword("_REFL_SSR");
                    }
                    break;
                case RelectionType.Sky:
                    {
                        mat.DisableKeyword("_REFL_OFF");
                        mat.EnableKeyword("_REFL_SKY_ONLY");
                        mat.DisableKeyword("_REFL_SSR");
                    }
                    break;
                case RelectionType.SkyAndObjects:
                    {
                        mat.DisableKeyword("_REFL_OFF");
                        mat.DisableKeyword("_REFL_SKY_ONLY");
                        mat.EnableKeyword("_REFL_SSR");
                    }
                    break;
                default:
                    break;
            }

            // General
            Vector3 lightDir = Vector3.up;

            if (sun != null)
            {
                lightDir = -sun.transform.forward;
            }

            Vector4 dwColorUnlit = mat.GetColor("_DeepWaterColorUnlit");
            float dwIntensityZenith = mat.GetFloat("_DeepWaterIntensityZenith");
            float dwIntensityHorizon = mat.GetFloat("_DeepWaterIntensityHorizon");
            float dwIntensityDark = mat.GetFloat("_DeepWaterIntensityDark");

            float dwScalar = 0.0f;

            if (lightDir.y >= 0.0f)
            {
                dwScalar = Mathf.Lerp(dwIntensityHorizon, dwIntensityZenith, lightDir.y);
            }
            else
            {
                dwScalar = Mathf.Lerp(dwIntensityHorizon, dwIntensityDark, -lightDir.y);
            }

            mat.SetVector("_DeepWaterColor", dwColorUnlit * dwScalar);
            mat.SetFloat("_SpecularRoughness", specularRoughness);
            mat.SetFloat("_SpecularIntensity", specularIntensity);

            mat.SetFloat("_FogEnd", fogEnd);
            mat.SetFloat("_FogDensity", fogDensity);
            mat.SetColor("_FogColor", fogColor);

            //underMat.SetFloat("_FogEnd", fogEnd);
            //underMat.SetFloat("_FogDensity", fogDensity);
            //underMat.SetColor("_FogColor", fogColor);
        }

        protected void PreRender(Camera cam)
        {
            farPlaneDuringRendering = cam.farClipPlane;

            if (sceneCameraFixFarPlane && cam.cameraType == CameraType.SceneView)
            {
                cam.farClipPlane = sceneCameraFarPlane;
            }

            if (mainCameraOnly && cam != Camera.main)
            {
                return;
            }

            IList<Vector3> points;

            IntersectFrustumWaterPlane(cam, out points);

            // Does the view frustum intersect the ocean plane?
            if (points.Count > 0)
            {
                Plane waterPlane = new Plane(Vector3.up, Vector3.up * position);

                // Set up new view and projection matrices where the camera/projector position is always above the water
                Vector3 camPos = cam.transform.position;

                float minCamPos = position + scaleSum + 10.0f;
                camPos.y = Mathf.Max(minCamPos, camPos.y);

                // It is important that the focus point is below camPos at all times!
                Vector3 focus = cam.transform.position + cam.transform.forward * 5.0f;

                // Construct view frame
                Vector3 viewFrameZ = Vector3.Normalize(focus - camPos);
                Vector3 viewFrameX = Vector3.Cross(Vector3.up, viewFrameZ).normalized;
                Vector3 viewFrameY = Vector3.Cross(viewFrameZ, viewFrameX).normalized;

                Matrix4x4 viewFrame = new Matrix4x4();
                viewFrame.SetColumn(0, viewFrameX);
                viewFrame.SetColumn(1, viewFrameY);
                viewFrame.SetColumn(2, -viewFrameZ);
                viewFrame.SetColumn(3, new Vector4(camPos.x, camPos.y, camPos.z, 1.0f));

                // Construct view and projection matrices
                Matrix4x4 view = viewFrame.inverse;
                Matrix4x4 proj = cam.projectionMatrix;
                Matrix4x4 viewProj = proj * view;

                mat.SetMatrix("_Proj", proj);
                mat.SetMatrix("_InvView", view.inverse);

                // Project the intersection points of the frustum and water plane into ndc-space, as seen from the camera
                Vector3[] ndcPoints = ProjectPointsToNdc(viewProj, points);

                // Create a matrix that maps ndc-points that are within the bounding box of the water plane in (ndc-space) to [0,1]
                Matrix4x4 rangeMap = MapNdcBoundingBoxToFullscreen(ndcPoints);

                // The projector transform is from world-space to remapped ndc-space where only ndc-points inside the bounding box of the water plane lies within [0,1]
                Matrix4x4 toProjectorSpace = rangeMap * viewProj;
                Matrix4x4 fromProjectorSpace = toProjectorSpace.inverse;

                // Find out where the corners of the bounding box of the water plane intersect the water plane
                Vector2[] corners = {   new Vector2(0.0f, 0.0f), new Vector2(1.0f, 0.0f),
                                        new Vector2(1.0f, 1.0f), new Vector2(0.0f, 1.0f) };
                Color[] colors = { Color.red, Color.green, Color.blue, Color.black };

                Vector4[] viewCorners = new Vector4[4];

                for (int i = 0; i < corners.Length; i++)
                {
                    Vector2 corner = corners[i];

                    Vector3 near = new Vector3(corner.x, corner.y, -1.0f);
                    Vector3 far = new Vector3(corner.x, corner.y, 1.0f);
                    Vector3 start = fromProjectorSpace.MultiplyPoint(near);
                    Vector3 end = fromProjectorSpace.MultiplyPoint(far);
                    Vector3 dir = (end - start).normalized;

                    float d;
                    waterPlane.Raycast(new Ray(start, dir), out d);
                    Vector3 hit = start + dir * d;

                    if (DebugMode)
                    {
                        if (d > 0.0f)
                        {
                            Debug.DrawRay(start, (hit - start) * 0.5f, colors[i]);
                        }
                    }

                    viewCorners[i] = view.MultiplyPoint(hit);
                }

                // Set shader parameters
                mat.SetVector("_ViewCorner0", viewCorners[0]);
                mat.SetVector("_ViewCorner1", viewCorners[1]);
                mat.SetVector("_ViewCorner2", viewCorners[2]);
                mat.SetVector("_ViewCorner3", viewCorners[3]);
            }
        }

        protected void PostRender(Camera cam)
        {
            if (cam.cameraType == CameraType.SceneView)
            {
                cam.farClipPlane = farPlaneDuringRendering;
            }
        }

        public float GetHeightAt(Vector3 point)
        {
            Vector2 xz = VH.GetXZ(point);
            Vector4 locations = new Vector4(Vector2.Dot(VH.GetXY(waveDirection01), xz), Vector2.Dot(VH.GetZW(waveDirection01), xz), Vector2.Dot(VH.GetXY(waveDirection23), xz), Vector2.Dot(VH.GetZW(waveDirection23), xz));
            Vector4 sine = VH.Sin(VH.Mul((locations + waveOffsets), waveConstants)) * 0.5f + new Vector4(0.5f, 0.5f, 0.5f, 0.5f);
            float sum = Vector4.Dot(waveScales, VH.Pow(sine, waveExponents));
            return position + sum;
        }

        public void OnEnable()
        {
            //Camera.onPreCull += PreRender;
            //Camera.onPostRender += PostRender;
        }

        public void OnDisable()
        {
            //Camera.onPreCull -= PreRender;
            //Camera.onPostRender -= PostRender;
        }

        public void Start()
        {

        }

        public void Update()
        {
            UpdateParams();

            SendParamsToShader();
        }

        public void OnDrawGizmos()
        {
            if (DebugMode)
            {
                if (Camera.main != null)
                {
                    IList<Vector3> points;

                    IntersectFrustumWaterPlane(Camera.main, out points);

                    Gizmos.color = Color.red;

                    foreach (Vector3 p in points)
                    {
                        Gizmos.DrawSphere(p, 1.0f);
                    }
                }
            }
        }
        public void ChangeOceanLevel(float level)
        {
            this.Level = level;
            Vector3 position = this.gameObject.transform.position;
            //TerrainMap.GetInstance()._CausticsImageEffect.WaterLevel = this.Level;
            this.gameObject.transform.position = new Vector3(position.x, this.Level, position.z);
        }

        public void OceanMinWave()
        {
            waveAngles = new Vector4(0, 0, 0, 0);
            waveSpeeds = new Vector4(0, 0, 0, 0);
            waveScales = new Vector4(0, 0, 0, 0);
            waveLengths = new Vector4(0.1f, 0.1f, 0.1f, 0.1f);
            waveExponents = new Vector4(1, 1, 1, 1);
        }

    }
}
