
using Microsoft.MixedReality.Toolkit.Input;
using Microsoft.MixedReality.Toolkit.Utilities;
using UnityEngine;
using Xyro.Toolkit.Utility;

namespace Xyro.CircuitSimXR.Nick
{
    public class FingerTip : MonoBehaviour
    {

        public Handedness handedness;

        public TrackedHandJoint trackedHandJoint;

        private bool isPalmOn;
        public void SetIsPalmOn() { isPalmOn = true; }
        public void SetIsPalmOff() { isPalmOn = false; }

        private bool _isTrackingHand = false;


        private MixedRealityPose pose;

        [HideInInspector] public new Collider collider;

        private void Awake()
        {
            collider = GetComponent<Collider>();
        }

        private void Start()
        {
            
        }

        private void OnEnable()
        {
            if (handedness == Handedness.Left)
            {
                HandTrackingStatusNotifier.onTrackingHandLeftStart += HandleHandTrackingLeftStart;
                HandTrackingStatusNotifier.onTrackingHandLeftEnd += HandleHandTrackingLeftEnd;
            }
            else
            {
                HandTrackingStatusNotifier.onTrackingHandRightStart += HandleHandTrackingRightStart;
                HandTrackingStatusNotifier.onTrackingHandRightEnd += HandleHandTrackingRightEnd;
            }
        }

        private void Update()
        {
            if (isPalmOn)
            {
                collider.enabled = false;
            }
            else
            {
                collider.enabled = true;
            }

            if (!_isTrackingHand) return;
            if (HandJointUtils.TryGetJointPose(trackedHandJoint, handedness, out pose))
            {
                transform.position = pose.Position;
                transform.rotation = pose.Rotation;
            }
        }

        private void HandleHandTrackingLeftStart()
        {
            _isTrackingHand = true;
            collider.enabled = true;

        }

        private void HandleHandTrackingLeftEnd()
        {
            _isTrackingHand = false;
            collider.enabled = false;

            if (WireManager.Instance.PlacingHand == WireManager.WireHand.Left)
            {
                WireManager.Instance.CancelCurrentWire();
            }
        }

        private void HandleHandTrackingRightStart()
        {
            _isTrackingHand = true;
            collider.enabled = true;

        }

        private void HandleHandTrackingRightEnd()
        {
            _isTrackingHand = false;
            collider.enabled = false;

            if (WireManager.Instance.PlacingHand == WireManager.WireHand.Right)
            {
                WireManager.Instance.CancelCurrentWire();
            }
        }

        private void OnDisable()
        {
            if (handedness == Handedness.Left)
            {
                HandTrackingStatusNotifier.onTrackingHandLeftStart -= HandleHandTrackingLeftStart;
                HandTrackingStatusNotifier.onTrackingHandLeftEnd -= HandleHandTrackingLeftEnd;
            }
            else
            {
                HandTrackingStatusNotifier.onTrackingHandRightStart -= HandleHandTrackingRightStart;
                HandTrackingStatusNotifier.onTrackingHandRightEnd -= HandleHandTrackingRightEnd;
            }

        }
    }
}
