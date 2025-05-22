using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Xyro.CircuitSimXR.Phil;
using Xyro.Toolkit.Utility.Snapping;
using Xyro.CircuitSimXR.Alex;

public class SnappableGrid : MonoBehaviour
{

    public void OnSnappableVolumeStart()
    {
            

    }

    // Update is called once per frame
    void Update()
    {
        
    }


    public GameObject FindNearestGridPoint(Vector3 componentPosition, float maxDistance)
    {
        GameObject nearestGridPoint = null;
        float minDistance = Mathf.Infinity;

        foreach (GameObject gridPoint in GameManager.Instance.gridPoints)
        {
            if (gridPoint == null) continue; 

            float distance = Vector3.Distance(componentPosition, gridPoint.transform.position);
            if (distance < minDistance)
            {
                minDistance = distance;
                nearestGridPoint = gridPoint;
            }
        }

        return (minDistance < maxDistance) ? nearestGridPoint : null;
    } 

}
