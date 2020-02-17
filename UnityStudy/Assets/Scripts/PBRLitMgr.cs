using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PBRLitMgr : MonoBehaviour
{
    public Light[] SphereLitList;
    public Light[] SpotLitList;
    public Light Sun;
    void Start()
    {
    }

    void Update()
    {
        // Sphere Light
        Vector4[] SphereLitPosList = new Vector4[4];
        Vector4[] SphereLitColList = new Vector4[4];
        for (int i = 0; i < SphereLitList.Length; i++)
        {
            SphereLitPosList[i] = new Vector4(SphereLitList[i].transform.position.x,
                                        SphereLitList[i].transform.position.y,
                                        SphereLitList[i].transform.position.z,
                                        SphereLitList[i].range);
            SphereLitColList[i] = new Vector4(SphereLitList[i].color.r,
                                        SphereLitList[i].color.g,
                                        SphereLitList[i].color.b,
                                        SphereLitList[i].intensity);
        }
        Shader.SetGlobalFloat("_SphereLitCount", SphereLitList.Length);
        Shader.SetGlobalVectorArray("_SphereLitPosList", SphereLitPosList);
        Shader.SetGlobalVectorArray("_SphereLitColList", SphereLitColList);

        // Spot Light
        Vector4[] SpotLitPosList = new Vector4[4];
        Vector4[] SpotLitColList = new Vector4[4];
        Vector4[] SpotLitDirList = new Vector4[4];
        
        for (int i = 0; i < SpotLitList.Length; i++)
        {
            SpotLitPosList[i] = new Vector4(SpotLitList[i].transform.position.x,
                                        SpotLitList[i].transform.position.y,
                                        SpotLitList[i].transform.position.z,
                                        SpotLitList[i].range);
            SpotLitColList[i] = new Vector4(SpotLitList[i].color.r,
                                        SpotLitList[i].color.g,
                                        SpotLitList[i].color.b,
                                        SpotLitList[i].intensity);
            SpotLitDirList[i] = new Vector4(SpotLitList[i].transform.forward.x,
                                        SpotLitList[i].transform.forward.y,
                                        SpotLitList[i].transform.forward.z,
                                        Mathf.Cos(SpotLitList[i].spotAngle/2));
        }
        Shader.SetGlobalFloat("_SpotLitCount", SpotLitList.Length);
        Shader.SetGlobalVectorArray("_SpotLitPosList", SpotLitPosList);
        Shader.SetGlobalVectorArray("_SpotLitColList", SpotLitColList);
        Shader.SetGlobalVectorArray("_SpotLitDirList", SpotLitDirList);
    }
}
