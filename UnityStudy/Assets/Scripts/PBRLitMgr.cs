using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PBRLitMgr : MonoBehaviour
{
    public Light[] litList;
    void Start()
    {
        
    }

    void FixedUpdate()
    {
        // 灯光参数
        Vector4[] litPosList = new Vector4[8];
        Vector4[] litColList = new Vector4[8];
        for (int i = 0; i < litList.Length; i++)
        {
            litPosList[i] = new Vector4(litList[i].transform.position.x,
                                        litList[i].transform.position.y,
                                        litList[i].transform.position.z,
                                        litList[i].range);
            litColList[i] = new Vector4(litList[i].color.r,
                                        litList[i].color.g,
                                        litList[i].color.b,
                                        litList[i].intensity);
        }
        Shader.SetGlobalFloat("_LitCount", litList.Length);
        Shader.SetGlobalVectorArray("_LitPosList", litPosList);
        Shader.SetGlobalVectorArray("_LitColList", litColList);
    }
}
