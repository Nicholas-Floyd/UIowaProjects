using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using Microsoft.MixedReality.Toolkit.Input;
using Microsoft.MixedReality.Toolkit.UI;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using Xyro.CircuitSimXR.Alex;
using Xyro.CircuitSimXR.Phil;
using Xyro.Toolkit.Utility;
using Xyro.Toolkit.Utility.ObjectPooling;
using Xyro.Toolkit.Utility.Snapping;
using static Xyro.Toolkit.Core.Enums;

namespace Xyro.CircuitSimXR.Nick
{
    public class CircuitComponent : MonoBehaviour
    {

        [SerializeField] private int _id = -1;
        public int Id
        {
            get { return _id; }
            set { _id = value; }
        }


        public CircuitComponentData data;
        //public CircuitPin[] pins;

        private float maxDistance = 0.3f;

        private ObjectManipulator manipulator;
        private NearInteractionGrabbable grabbable;
        private Collider col;

        public GameObject highlight;

        public CircuitComponentDefaults defaults;

        public Terminal[] terminals = new Terminal[2];
        public float numericValue;   // holds float values like resistance, capacitance, etc.
        public bool boolValue;
        public GameObject lastSnappedGridPoint;
        public GameObject numericValueBox;

        public TMP_Text numericValueText;





        private void Awake()
        {
            manipulator = GetComponent<ObjectManipulator>();
            grabbable = GetComponent<NearInteractionGrabbable>();
            col = GetComponent<Collider>();
            highlight.SetActive(false);

            if (manipulator == null)
                Debug.LogWarning($"[CircuitComponent] ObjectManipulator missing on {gameObject.name}");

            if (grabbable == null)
                Debug.LogWarning($"[CircuitComponent] NearInteractionGrabbable missing on {gameObject.name}");

            if (col == null)
                Debug.LogWarning($"[CircuitComponent] Collider missing on {gameObject.name}");

        }


        private void OnEnable()
        {
            GameManager.Instance.onGameStateChange += HandleGameStateChange;
            GameManager.Instance.onComponentStateChanged += HandleComponentStateChange;
        }

        private void HandleGameStateChange(GameState gameState)
        {
            if (!gameObject.activeSelf)  return;

            highlight.SetActive(false);

            
            if (gameState == GameState.COMPONENT_STATE)
            {
                    manipulator.enabled = true;
                    grabbable.enabled = true;
            }
            else
            {
                manipulator.enabled = false;
                grabbable.enabled = false;
            }
        }

        private void HandleComponentStateChange(ComponentState componentState)
        {
            if (!gameObject.activeSelf) return;
            
            if(componentState == ComponentState.COMPONENT_PLACE || componentState == ComponentState.COMPONENT_EDIT)
            {
                manipulator.enabled = true;
                grabbable.enabled = true;
            }
            else
            {
                manipulator.enabled= false;
                grabbable.enabled= false;   
            }
            
           
        }

        private void Start()
        {
            if (data == null)
            {
                Debug.LogWarning($"[CircuitComponent] 'data' is null on {gameObject.name}. Skipping default assignment.");
                return;
            }

            if (defaults == null)
            {
                Debug.LogWarning($"[CircuitComponent] 'defaults' is null on {gameObject.name}. Skipping default assignment.");
                return;
            }
            numericValueText.text = "";


            switch (data.componentType)
            {
                case ComponentType.Resistor:
                    numericValue = defaults.resistorResistance;
                    break;

                case ComponentType.Capacitor:
                    numericValue = defaults.capacitorCapacitance;
                    break;

                case ComponentType.Inductor:
                    numericValue = defaults.inductorInductance;
                    break;

                case ComponentType.VoltageSource:
                    numericValue = defaults.batteryVoltage;
                    break;

                case ComponentType.Diode:
                    boolValue = defaults.diodeLit;
                    break;

                case ComponentType.Switch:
                    boolValue = defaults.switchOpen; // closed by default
                    break;

                default:
                    Debug.LogWarning($"[CircuitComponent] Unsupported component type: {data.componentType}");
                    break;
            }
        }


        IEnumerator DelayedActionFunction(Collision collision)
        {
            highlight.SetActive(true);
            if (data.componentType != ComponentType.Diode && data.componentType != ComponentType.Switch)
            {
                if (data.componentType == ComponentType.VoltageSource && numericValue >= 500)
                {
                    numericValue = 1;
                }
                else if (data.componentType != ComponentType.VoltageSource && numericValue > 1000)
                {
                    numericValue = 0.00001f;

                }
                else if (data.componentType == ComponentType.VoltageSource && numericValue == 1)
                {
                    numericValue = 5;
                }
                else if (data.componentType == ComponentType.VoltageSource && numericValue == 5)
                {
                    numericValue = 9;
                }
                else if (data.componentType == ComponentType.VoltageSource && numericValue == 9)
                {
                    numericValue = 50;
                }
                else if (data.componentType == ComponentType.VoltageSource && numericValue == 50)
                {
                    numericValue = 100;
                }
                else if (data.componentType == ComponentType.VoltageSource && numericValue == 100)
                {
                    numericValue = 500;
                }
                else
                {
                    float[] steps = { 0.00001f, 0.0001f, 0.001f, 0.01f, 0.1f, 1f };
                    int index = Array.IndexOf(steps, numericValue);
                    if (index >= 0 && index < steps.Length - 1)
                    {
                        numericValue = steps[index + 1];
                    }

                    else
                    {
                        numericValue = numericValue * 10f;
                    }
                }

                switch (data.componentType)
                {
                    case ComponentType.Resistor:
                        numericValueText.text = GameManager.Instance.FormatWithSIUnit(numericValue, "Ω");
                        break;
                    case ComponentType.VoltageSource:
                        numericValueText.text = GameManager.Instance.FormatWithSIUnit(numericValue, "V");
                        break;
                    case ComponentType.Inductor:
                        numericValueText.text = GameManager.Instance.FormatWithSIUnit(numericValue, "H");
                        break;
                    case ComponentType.Capacitor:
                        numericValueText.text = GameManager.Instance.FormatWithSIUnit(numericValue, "F");
                        break;
                    case ComponentType.Switch:
                        numericValueText.text = boolValue ? "Closed" : "Open";
                        break;
                    case ComponentType.Diode:
                        numericValueText.text = "";
                        break;
                }

            }
            else if (data.componentType == ComponentType.Switch)
            {
                boolValue = !boolValue;
                if (boolValue) { numericValueText.text = "Closed" ; }
                else { numericValueText.text = "Open"; }
                
            }

            yield return new WaitForSeconds(5f);
            

        }

        private void OnCollisionEnter(Collision collision)
        {
            if(GameManager.Instance._componentState == ComponentState.COMPONENT_EDIT)
            {
                StartCoroutine(DelayedActionFunction(collision));
            }
            if (collision.collider == GameManager.Instance.ColliderIndexTipLeft)
            {
                GameManager.Instance.FistedCircuitComponentLeftId = Id;
            }
            if (collision.collider == GameManager.Instance.ColliderIndexTipRight)
            {
                GameManager.Instance.FistedCircuitComponentRightId = Id;
            }
            if(GameManager.Instance.GameState == GameState.SIMULATION)
            {
                GameManager.Instance.OnSimulateComponent(Id);
            }
            return;

        }

        private void OnCollisionExit(Collision collision)
        {
            if (collision.collider == GameManager.Instance.ColliderIndexTipLeft)
            {
                GameManager.Instance.FistedCircuitComponentLeftId = -1;
            }
            if (collision.collider == GameManager.Instance.ColliderIndexTipRight)
            {
                GameManager.Instance.FistedCircuitComponentRightId = -1;
            }
            if(GameManager.Instance._componentState == ComponentState.COMPONENT_EDIT)
            {
                highlight.SetActive(false);
            }
        }



        public Terminal[] GetTerminals()
        {
            return terminals;
        }

        public List<Terminal> GetUsedTerminals()
        {
            List<Terminal> used = new List<Terminal>();
            foreach (var t in terminals)
            {
                if (t != null && t.IsConnected)
                    used.Add(t);
            }
            return used;
        }

        public List<Terminal> GetUnusedTerminals()
        {
            List<Terminal> unused = new List<Terminal>();
            foreach (var t in terminals)
            {
                if (t != null && !t.IsConnected)
                    unused.Add(t);
            }
            return unused;
        }

        public void DeleteComponent()
        {
            Debug.Log($"[DeleteComponent] Deleting {name}");

            List<Wire> wiresToDelete = new List<Wire>();

            foreach (Terminal terminal in terminals)
            {
                wiresToDelete.AddRange(terminal.ConnectedWires);
            }

            foreach (Wire wire in wiresToDelete.Distinct())
            {
                WireManager.Instance.DeleteWire(wire);
            }
            GameManager.Instance.gridPointOccupied.Remove(lastSnappedGridPoint);

            CircuitManager.Instance.activeComponents.Remove(this);

            ObjectPooler.Instance.ReturnToPool(gameObject);
            gameObject.SetActive(false);

        }



        public void HandleManipulationStarted(ManipulationEventData eventData)
        {
            GameManager.Instance.CurrentComponentHeld = this;
            if(lastSnappedGridPoint == null)
            {
                return;
            } 
            else
            {
                GameManager.Instance.gridPointOccupied.Remove(lastSnappedGridPoint);
            }

            List<Wire> wiresToDelete = new List<Wire>();

            foreach (Terminal terminal in terminals)
            {
                wiresToDelete.AddRange(terminal.ConnectedWires);
            }

            foreach (Wire wire in wiresToDelete.Distinct())
            {
                WireManager.Instance.DeleteWire(wire);
            }
        }

        public void HandleManipulationEnded(ManipulationEventData eventData)
        {
            GameObject nearestGrid = GameManager.Instance.FindNearestGridPoint(transform.position, 2f);
            if (GameManager.Instance.gridPointOccupied.Contains(nearestGrid)){
                return;
            }
            if (nearestGrid != null)
            {
                transform.position = nearestGrid.transform.position;

                SnappableXR snappable = GetComponent<SnappableXR>();
                if (snappable != null)
                {
                    col = snappable.GetComponent<Collider>();
                    
                    snappable.SetSnapTransform(nearestGrid.transform);

                    
                    Snap(nearestGrid);
                    col.enabled = true;

                }
            }

            GameManager.Instance.CurrentComponentHeld = null;
        }

        public void Snap(GameObject gridPoint)
        {
            CircuitComponent objToSnap = GameManager.Instance.CurrentComponentHeld;
            Transform snapTransform = gridPoint.transform;
            Vector3 currPos;
            SnappableXR snapScript = objToSnap.GetComponent<SnappableXR>();

            //if (_isSnapped) return;
            if (XUtils.GetDistance(GameManager.Instance.CurrentComponentHeld.transform.position, snapTransform.position) <= maxDistance)
            {
                currPos = snapTransform.position;
                //_isSnapped = true;
                if (objToSnap.data.componentType == ComponentType.VoltageSource)
                {
                    currPos.y -= 0.1f;
                    objToSnap.transform.position = currPos;
                    objToSnap.transform.rotation = Quaternion.Euler(0f, 0f, 0f);

                }
                else if(objToSnap.data.componentType == ComponentType.Capacitor)
                {
                    currPos.y += 0.04f;
                    objToSnap.transform.position = currPos;
                    objToSnap.transform.rotation = Quaternion.Euler(-90f, 0f, 0f);
                }
                else if (objToSnap.data.componentType == ComponentType.Resistor)
                {
                    currPos.y -= 0.08f;
                    objToSnap.transform.position = currPos;
                    objToSnap.transform.rotation = Quaternion.Euler(-180f, 0f, 0f);
                }
                else if (objToSnap.data.componentType == ComponentType.Inductor)
                {
                    currPos.y -= 0.035f;
                    objToSnap.transform.position = currPos;
                    objToSnap.transform.rotation = Quaternion.Euler(0f, 0f, -90f);
                }
                else if (objToSnap.data.componentType == ComponentType.Switch)
                {
                    currPos.y -= 0.025f;
                    objToSnap.transform.position = currPos;
                    objToSnap.transform.rotation = Quaternion.Euler(0f, 0f, 0f);
                }
                else
                {
                    objToSnap.transform.position = snapTransform.position;
                    objToSnap.transform.rotation = Quaternion.Euler(-90f, 0f, 0f);

                }
                GameManager.Instance.gridPointOccupied.Add(gridPoint);
                lastSnappedGridPoint = gridPoint;
                snapScript.OnSnapped?.Invoke(); // Triggers the snap event
                }
            }
    }




}





