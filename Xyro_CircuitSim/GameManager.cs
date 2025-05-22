

using Microsoft.MixedReality.Toolkit.UI;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Security.Policy;
using TMPro;
using UnityEngine;
using UnityEngine.UIElements;
using Xyro.CircuitSimXR.Nick;
using Xyro.CircuitSimXR.Phil;
using Xyro.Toolkit.Core;
using Xyro.Toolkit.Utility;
using Xyro.Toolkit.Utility.ObjectPooling;
using static Unity.Burst.Intrinsics.X86.Avx;

namespace Xyro.CircuitSimXR.Alex
{
    public class GameManager : Singleton<GameManager>
    {
        public event Action<GameState> onGameStateChange;

        public event Action<GameSubstate> onGameSubstateChanged;
        public event Action<ComponentState> onComponentStateChanged;
        public event Action<WireState> onWireStateChanged;
        public event Action<int> onSimulateComponent;

        public SnackbarController snackbarController;

        public GameObject snappableVolume;
        public List<GameObject> gridPoints = new List<GameObject>();
        public List<GameObject> gridPointOccupied = new List<GameObject>();

        public GameObject componentSpawnMenu;

        public GameObject mainMenu;
        public GameObject componentMenu;
        public GameObject wireMenu;
        public GameObject analysisMenu;
        public GameObject userInfoMenu;

        [Header("Main Menu Interactables")]
        public Interactable componentsInteractable;
        public Interactable wiresInteractable;
        public Interactable simulationsInteractable;

        [Header("Component Menu Interactables")]
        public Interactable componentPlaceInteractable;
        public Interactable componentEditInteractable;
        public Interactable componentDeleteInteractable;

        [Header("Wire Menu Interactables")]
        public Interactable wirePlaceInteractable;
        public Interactable wireDeleteInteractable;

        public string defaultComponent = "Battery"; // Default object to spawn

        public GameObject indexTipLeft;
        public GameObject indexTipRight;

        private CircuitComponent _currentComponentHeld;
        public CircuitComponent CurrentComponentHeld
        {
            get { return _currentComponentHeld; }
            set { _currentComponentHeld = value; }
        }



        private int _fistedCircuitComponentLeftId;
        public int FistedCircuitComponentLeftId
        {
            get { return _fistedCircuitComponentLeftId; }
            set { _fistedCircuitComponentLeftId = value; }
        }

        private int _fistedCircuitComponentRightId;
        public int FistedCircuitComponentRightId
        {
            get { return _fistedCircuitComponentRightId; }
            set { _fistedCircuitComponentRightId = value; }
        }
        private Collider _colliderIndexTipLeft;

        public Collider ColliderIndexTipLeft
        {
            get { return _colliderIndexTipLeft; }
            set { _colliderIndexTipLeft = value; }
        }

        private Collider _colliderIndexTipRight;

        public Collider ColliderIndexTipRight
        {
            get { return _colliderIndexTipRight; }
            set { _colliderIndexTipRight = value; }
        }

        private GameState _gameState = GameState.LOADING;
        private GameSubstate _gameSubstate = GameSubstate.MENU;
        private WireState _wireState;
        public ComponentState _componentState;
        public ComponentState prevComponentState;




        public void OnSimulateComponent(int id)
        {
            onSimulateComponent?.Invoke(id);
        }


        public GameSubstate GameSubstate
        {
            get { return _gameSubstate; }
            set
            {
                if (_gameSubstate == value)
                {
                    XUtils.LogError($"Game Substate is already set to {value}");
                    return;
                }
                _gameSubstate = value;
                XUtils.Log($"Game Substate is already set  to {value}");

                onGameSubstateChanged?.Invoke(_gameSubstate);

            }

        }
        public ComponentState ComponentState
        {
            get { return _componentState; }
            set
            {
                if (_componentState == value)
                {
                    XUtils.LogError($"Component State is already set to {value}");
                    return;
                }
                _componentState = value;
                XUtils.Log($"Component State is already set  to {value}");

                onComponentStateChanged?.Invoke(_componentState);

            }

        }

        public GameState GameState
        {
            get { return _gameState; }
            set
            {
                if (_gameState == value)
                {
                    XUtils.LogWarning($"Game State is already set to {value}");

                    return;
                }
                _gameState = value;
                if (_gameState == GameState.COMPONENT_STATE)
                {
                    XUtils.Log("Switching to component state}");
                    _componentState = ComponentState.COMPONENT_PLACE;
                    componentMenu.SetActive(true);
                    userInfoMenu.SetActive(true);
                    wireMenu.SetActive(false);
                    analysisMenu.SetActive(false);

                }
                if (_gameState == GameState.WIRE_STATE)
                {
                    XUtils.Log("Switching to wire state}");
                    _wireState = WireState.WIRE_PLACE;
                    wireMenu.SetActive(true);
                    componentMenu.SetActive(false);
                    componentSpawnMenu.SetActive(false);
                    analysisMenu.SetActive(false);
                    userInfoMenu.SetActive(false);

                }
                if (_gameState == GameState.SIMULATION)
                {
                    XUtils.Log("Switching to simulation state");
                    wireMenu.SetActive(false);
                    componentMenu.SetActive(false);
                    componentSpawnMenu.SetActive(false);
                    analysisMenu.SetActive(true);
                    userInfoMenu.SetActive(false);

                }
                XUtils.Log($"Game State set to:{value}");

                onGameStateChange?.Invoke(_gameState);


            }
        }
        public WireState WireState
        {
            get { return _wireState; }
            set
            {
                if (_wireState == value)
                {
                    XUtils.LogError($"Wire Substate is already set to {value}");
                    return;
                }
                _wireState = value;
                XUtils.Log($"wire Substate is already set  to {value}");

                onWireStateChanged?.Invoke(_wireState);

            }

        }

        protected override void Awake()
        {
            base.Awake();
            SetSnappableVolume();
        }

        private void HandleLoadingCompleted()
        {
            XUtils.LogWarning($"GAMEMANAGER ONLOADINGCOMPLETED -> START COMPONENT PLACING");
            GameState = GameState.MENU;
            ObjectPooler.Instance.onLoadingPercentageUpdate += HandlePoolLoadingPercent;
        }

        private void HandlePoolLoadingPercent(float percent)
        {
            if (percent >= 1.0f)
            {
                ObjectPooler.Instance.onLoadingPercentageUpdate -= HandlePoolLoadingPercent;
                //PooledComponentTracker.Instance.InitializeTracker();
                Debug.Log("[GameManager] Object pooling complete. Tracker initialized.");
            }
        }


        public void ShowSnackbar(string message)
        {
            snackbarController.ShowSnackbar(message);
        }
        public void OnStartButtonClick()
        {
            for (int i = 0; i < ObjectPooler.Instance.gameObject.transform.childCount; i++) {
                if (ObjectPooler.Instance.gameObject.transform.GetChild(i).CompareTag("Wire"))
                {
                    WireManager.Instance.InitComponent(ObjectPooler.Instance.gameObject.transform.GetChild(i).GetComponent<Wire>(), i);

                }

                CircuitManager.Instance.InitComponent(ObjectPooler.Instance.gameObject.transform.GetChild(i).GetComponent<CircuitComponent>(), i);
                //CircuitManager.Instance.allComponents.Add(ObjectPooler.Instance.gameObject.transform.GetChild(i).GetComponent<CircuitComponent>());
            }
            StartCoroutine(Co_InitCircuitComponentIds());
        }

        private IEnumerator Co_InitCircuitComponentIds()
        {
            if (CircuitManager.Instance.allComponents.Count != ObjectPooler.Instance.gameObject.transform.childCount)
            {
                yield return null;
            }
            XRManager.Instance.mixedRealitySceneGameObject.SetActive(true);
            GameState = GameState.COMPONENT_STATE;
            prevComponentState = ComponentState.COMPONENT_PLACE;
        }


        public void OnMenuButtonClick(int gameState)
        {
            Debug.Log($"[OnMenuButtonClick] Trying to set GameState to: {(GameState)gameState}");
            GameState = (GameState)gameState;

            AudioManager.Instance.Play("poof");

            if (ComponentState == ComponentState.COMPONENT_EDIT || (prevComponentState == ComponentState.COMPONENT_EDIT))
            {
                for (int i = 0; i < CircuitManager.Instance.activeComponents.Count; i++)
                {
                    CircuitManager.Instance.activeComponents[i].numericValueBox.SetActive(false);
                }
                prevComponentState = ComponentState.COMPONENT_PLACE;

            }
            if (GameState != GameState.SIMULATION)
            {
                // Reset all diodes to unlit when leaving simulation
                foreach (var c in CircuitManager.Instance.activeComponents)
                {
                    if (c.data.componentType == ComponentType.Diode)
                    {
                        var diodeBehavior = c.gameObject.GetComponent<DiodeBehavior>();
                        if (diodeBehavior != null)
                        {
                            diodeBehavior.SetLitState(false);
                        }
                    }
                }

            }

            if(GameState == GameState.COMPONENT_STATE)
            {
                if (ComponentState == ComponentState.COMPONENT_PLACE)
                {
                    componentSpawnMenu.SetActive(true);
                    userInfoMenu.SetActive(true);   
                }
                wiresInteractable.IsToggled = false;
                simulationsInteractable.IsToggled = false;
                componentPlaceInteractable.IsToggled = true;
                componentEditInteractable.IsToggled = false;
                componentDeleteInteractable.IsToggled = false;
                prevComponentState = ComponentState.COMPONENT_PLACE;

            }
            else if (GameState == GameState.WIRE_STATE)
            {
                componentsInteractable.IsToggled = false;  
                simulationsInteractable.IsToggled = false;
                wirePlaceInteractable.IsToggled = true;
                wireDeleteInteractable.IsToggled = false;
                ComponentState = ComponentState.COMPONENT_PLACE;
                prevComponentState = ComponentState.COMPONENT_PLACE;

            }
            else if(GameState == GameState.SIMULATION)
            {
                componentsInteractable.IsToggled= false;
                wiresInteractable.IsToggled = false;
                ComponentState = ComponentState.COMPONENT_PLACE;
                prevComponentState = ComponentState.COMPONENT_PLACE;

            }


        }

        public void EnableColliders()
        {
            _colliderIndexTipLeft.enabled = true;
            _colliderIndexTipRight.enabled = true;
        }
        private void Start()
        {
            HandleLoadingCompleted();
            wireMenu.SetActive(false);

            _colliderIndexTipLeft = indexTipLeft.GetComponent<Collider>();
            _colliderIndexTipRight = indexTipRight.GetComponent<Collider>();

            _colliderIndexTipLeft.enabled = true;
            _colliderIndexTipRight.enabled = true;

            //indexTipLeft.GetComponent <Collider>().enabled = true;
            //indexTipRight.GetComponent <Collider>().enabled = true;

        }
        public void OnComponentMenuButtonClick(int componentState)
        {
            ComponentState = (ComponentState)componentState;
            

            if (ComponentState == ComponentState.COMPONENT_PLACE)
            {
                componentSpawnMenu.SetActive(true);
                userInfoMenu.SetActive(true);   
                componentEditInteractable.IsToggled = false;
                componentDeleteInteractable.IsToggled = false;
            }
            else if (ComponentState == ComponentState.COMPONENT_EDIT)
            {
                prevComponentState = ComponentState.COMPONENT_EDIT;
                UpdateValueText();


                componentSpawnMenu.SetActive(false);
                userInfoMenu.SetActive(false);
                componentPlaceInteractable.IsToggled = false;
                componentDeleteInteractable.IsToggled = false;
                //AnalyzeFunctions.Instance.RunACAnalysis();
            }
            else if (ComponentState == ComponentState.COMPONENT_DELETE)
            {
                componentSpawnMenu.SetActive(false);
                userInfoMenu.SetActive(false);  
                componentPlaceInteractable.IsToggled = false;
                componentEditInteractable.IsToggled = false;
            }
            if (ComponentState != ComponentState.COMPONENT_EDIT && (prevComponentState == ComponentState.COMPONENT_EDIT))
            {
                for (int i = 0; i < CircuitManager.Instance.activeComponents.Count; i++)
                {
                    CircuitManager.Instance.activeComponents[i].numericValueBox.SetActive(false);
                    prevComponentState = ComponentState;
                }
            }
            else
            {
                prevComponentState = ComponentState;

            }

        }
        public void OnWireMenuButtonClick(int wireState)
        {
            prevComponentState = ComponentState.COMPONENT_PLACE;
            ComponentState = ComponentState.COMPONENT_PLACE;
            WireState = (WireState)wireState;

            if (WireState == WireState.WIRE_PLACE)
            {
                wireDeleteInteractable.IsToggled = false;
            }
            else if (WireState == WireState.WIRE_EDIT)
            {
                wirePlaceInteractable.IsToggled = false;
                wireDeleteInteractable.IsToggled = false;
            }
            else if (WireState == WireState.WIRE_DELETE)
            {
                wirePlaceInteractable.IsToggled = false;
            }
        }
       

         public void SetSnappableVolume()
         {
             snappableVolume.transform.position = XRManager.Instance.transform.position;
             snappableVolume.transform.rotation = Quaternion.Euler(0,XRManager.Instance.transform.rotation.y,0);

            gridPoints.Clear();

             foreach(Transform child in snappableVolume.transform)
             {
                 gridPoints.Add(child.gameObject);
             }

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


        private void OnEnable()
        {
            HandsManager.onPinchingLeftStart += HandleOnPinchingLeftStart;
            HandsManager.onPinchingRightStart += HandleOnPinchingRightStart;

        }

        private void OnDisable()
        {
            HandsManager.onPinchingLeftStart -= HandleOnPinchingLeftStart;
            HandsManager.onPinchingRightStart -= HandleOnPinchingRightStart;

        }


        private void HandleOnPinchingLeftStart()
        {

            if (GameState == GameState.COMPONENT_STATE)
            {
                if (ComponentState == ComponentState.COMPONENT_DELETE)
                {

                    if (FistedCircuitComponentLeftId != -1)
                    {
                        CircuitComponent comp = CircuitManager.Instance.activeComponents.Find(c => c.Id == FistedCircuitComponentLeftId);
                        if (comp != null)
                        {
                            comp.DeleteComponent();
                            FistedCircuitComponentLeftId = -1;
                        }
                    }
                }
            }
            else if (GameState == GameState.WIRE_STATE)
            {
                if (WireState == WireState.WIRE_DELETE)
                {
                    if (WireManager.Instance.FistedWireLeftId != -1)
                    {
                        Wire wire = WireManager.Instance.activeWires.Find(c => c.id == WireManager.Instance.FistedWireLeftId);
                        if (wire != null)
                        {
                            WireManager.Instance.DeleteWire(wire);
                            WireManager.Instance.FistedWireLeftId = -1;
                        }
                    }

                }
                else if (WireState == WireState.WIRE_PLACE)
                {
                    if (!WireManager.Instance.IsPlacingWire())
                    {
                        WireManager.Instance.StartWire(indexTipLeft.transform.position, true);
                    }
                    else
                    {
                        WireManager.Instance.EndWire(indexTipLeft.transform.position, true);
                    }
                }
            }
        
        }



        private void HandleOnPinchingRightStart()
        {

            if (GameState == GameState.COMPONENT_STATE)
            {
                if (ComponentState == ComponentState.COMPONENT_DELETE)
                {

                    if (FistedCircuitComponentRightId != -1)
                    {
                        CircuitComponent comp = CircuitManager.Instance.activeComponents.Find(c => c.Id == FistedCircuitComponentRightId);
                        if (comp != null)
                        {
                            comp.DeleteComponent();
                            FistedCircuitComponentRightId = -1;
                        }
                    }
                }
            }
            else if (GameState == GameState.WIRE_STATE)
            {
                if (WireState == WireState.WIRE_DELETE)
                {
                    if (WireManager.Instance.FistedWireRightId != -1)
                    {
                        Wire wire = WireManager.Instance.activeWires.Find(c => c.id == WireManager.Instance.FistedWireRightId);
                        if (wire != null)
                        {
                            WireManager.Instance.DeleteWire(wire);
                            WireManager.Instance.FistedWireRightId = -1;
                        }
                    }

                }
                else if (WireState == WireState.WIRE_PLACE)
                {
                    if (!WireManager.Instance.IsPlacingWire())
                    {
                        WireManager.Instance.StartWire(indexTipRight.transform.position, false);
                    }
                    else
                    {
                        WireManager.Instance.EndWire(indexTipRight.transform.position, false);
                    }
                }
            }

        }


        public string FormatWithSIUnit(float value, string unit)
        {
            double absValue = Math.Abs(value);
            string sign = value < 0 ? "-" : "";

            if (absValue >= 1e9)
                return sign + (absValue / 1e9).ToString("F2") + " G" + unit;  // giga
            else if (absValue >= 1e6)
                return sign + (absValue / 1e6).ToString("F2") + " M" + unit;  // mega
            else if (absValue >= 1e3)
                return sign + (absValue / 1e3).ToString("F2") + " k" + unit;  // kilo
            else if (absValue >= 1)
                return sign + absValue.ToString("F2") + " " + unit;           // base
            else if (absValue >= 1e-3)
                return sign + (absValue * 1e3).ToString("F2") + " m" + unit; // milli
            else if (absValue >= 1e-6)
                return sign + (absValue * 1e6).ToString("F2") + " μ" + unit; // micro
            else if (absValue >= 1e-9)
                return sign + (absValue * 1e9).ToString("F2") + " n" + unit; // nano
            else
                return sign + "0 " + unit; // fallback for near zero
        }

      
        private void UpdateValueText()
        {
            foreach (var component in CircuitManager.Instance.activeComponents)
            {
                component.numericValueBox.SetActive(true);

                switch (component.data.componentType)
                {
                    case ComponentType.Resistor:
                        component.numericValueText.text = FormatWithSIUnit(component.numericValue, "Ω");
                        break;
                    case ComponentType.VoltageSource:
                        component.numericValueText.text = FormatWithSIUnit(component.numericValue, "V");
                        break;
                    case ComponentType.Inductor:
                        component.numericValueText.text = FormatWithSIUnit(component.numericValue, "H");
                        break;
                    case ComponentType.Capacitor:
                        component.numericValueText.text = FormatWithSIUnit(component.numericValue, "F");
                        break;
                    case ComponentType.Switch:
                        component.numericValueText.text = component.boolValue ? "Closed" : "Open";
                        break;
                    case ComponentType.Diode:
                        component.numericValueText.text = "";
                        break;
                }
            }
        }


    }
}
