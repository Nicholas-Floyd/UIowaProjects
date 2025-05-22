using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Xyro.CircuitSimXR.Alex;

namespace Xyro.CircuitSimXR.Nick
{
     public class Wire : MonoBehaviour
     {
        public float wireSize;
        public int id;
        public Terminal startTerminal;
        public Terminal endTerminal;

        public LineRenderer lineRenderer;
        private BoxCollider wireCollider;

        private void Awake()
        {
            wireCollider = GetComponent<BoxCollider>();
            if (wireCollider == null)
            {
                wireCollider = gameObject.AddComponent<BoxCollider>();
            }
        }

        public void UpdateCollider()
        {
            if (startTerminal == null || endTerminal == null) return;

            Vector3 start = startTerminal.transform.position;
            Vector3 end = endTerminal.transform.position;

            Vector3 center = (start + end) / 2f;
            Vector3 direction = end - start;

            transform.position = center;
            transform.rotation = Quaternion.LookRotation(direction.normalized);
            wireCollider.size = new Vector3(wireSize, wireSize, direction.magnitude); // thin width, full length
        }


        private void OnCollisionEnter(Collision collision)
        {

            if (collision.collider == WireManager.Instance.ColliderIndexTipLeft)
            {
                WireManager.Instance.FistedWireLeftId = id;
            }
            if (collision.collider == WireManager.Instance.ColliderIndexTipRight)
            {
                WireManager.Instance.FistedWireRightId = id;
            }
            return;

        }

        private void OnCollisionExit(Collision collision)
        {
            if (collision.collider == WireManager.Instance.ColliderIndexTipLeft)
            {
                WireManager.Instance.FistedWireLeftId = -1;
            }
            if (collision.collider == WireManager.Instance.ColliderIndexTipRight)
            {
                WireManager.Instance.FistedWireRightId = -1;
            }
        }


    }
}


