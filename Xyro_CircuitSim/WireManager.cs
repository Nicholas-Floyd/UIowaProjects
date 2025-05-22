using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Xyro.CircuitSimXR.Alex;
using Xyro.CircuitSimXR.Nick;
using Xyro.Toolkit.DevTools;
using Xyro.Toolkit.Utility;
using Xyro.Toolkit.Utility.ObjectPooling;


public class WireManager : Singleton<WireManager>
{
    public enum WireHand { None, Left, Right }
    public FingerTip fingerTipLeft;
    public FingerTip fingerTipRight;
    public FingerTip activeFingerTip;

    public Material wireMaterial;

    private Wire currentWire;
    private LineRenderer currentLine;
    private Terminal startTerminal;
    private bool isPlacingWire = false;
    private WireHand placingHand;
    public WireHand PlacingHand => placingHand;

    public bool IsPlacingWire() => isPlacingWire;

    private int _fistedWireLeftId;
    public int FistedWireLeftId
    {
        get { return _fistedWireLeftId; }
        set { _fistedWireLeftId = value; }
    }
    private int _fistedWireRightId;
    public int FistedWireRightId
    {
        get { return _fistedWireRightId; }
        set { _fistedWireRightId = value; }
    }


    public List<Wire> allWires = new List<Wire>();
    public List<Wire> activeWires = new List<Wire>();

    public GameObject indexTipLeft;
    public GameObject indexTipRight;

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


    [SerializeField] private float maxSnapDistance = 0.1f;


    private void Start()
    {
        placingHand = WireHand.None;
        activeFingerTip = null;

        _colliderIndexTipLeft = indexTipLeft.GetComponent<Collider>();
        _colliderIndexTipRight = indexTipRight.GetComponent<Collider>();

        _colliderIndexTipLeft.enabled = true;
        _colliderIndexTipRight.enabled = true;

    }

    void Update()
    {
        if (!isPlacingWire || GameManager.Instance.GameState != GameState.WIRE_STATE || activeFingerTip == null)
        {
            return;
        }

        if (placingHand != WireHand.None && currentWire != null && activeFingerTip != null)
        {
            currentWire.lineRenderer.SetPosition(1, activeFingerTip.transform.position);
        }
    }

    public void StartWire(Vector3 fingerTipPosition, bool isLeftHand)
    {
        if (GameManager.Instance.WireState != WireState.WIRE_PLACE) return;

        int componentId = isLeftHand
            ? GameManager.Instance.FistedCircuitComponentLeftId
            : GameManager.Instance.FistedCircuitComponentRightId;

        placingHand = isLeftHand ? WireHand.Left : WireHand.Right;
        if (placingHand == WireHand.Left)
            activeFingerTip = fingerTipLeft;
        else if (placingHand == WireHand.Right)
            activeFingerTip = fingerTipRight;

        CircuitComponent component = CircuitManager.Instance.activeComponents.Find(c => c.Id == componentId);
        if (component == null) return;

        Terminal nearest = GetNearestTerminal(component, fingerTipPosition);
        if (nearest == null) return;

        GameObject obj = ObjectPooler.Instance.SpawnFromPool("Wire");
        if (obj == null)
        {
            Debug.LogError("Wire pool returned null!");
            return;
        }

        obj.SetActive(true);

        currentWire = obj.GetComponent<Wire>();
        activeWires.Add(currentWire);
        currentLine = currentWire.lineRenderer;

        currentWire.startTerminal = nearest;
        startTerminal = nearest;

        currentLine.SetPosition(0, nearest.transform.position);
        currentLine.SetPosition(1, fingerTipPosition);

        nearest.OnConnect(currentWire);
        isPlacingWire = true;
    }

    public void EndWire(Vector3 fingerTipPosition, bool isLeftHand)
    {
        Debug.Log("[WireManager] EndWire() called");

        if (!isPlacingWire) return;

        int componentId = isLeftHand
            ? GameManager.Instance.FistedCircuitComponentLeftId
            : GameManager.Instance.FistedCircuitComponentRightId;

        CircuitComponent component = CircuitManager.Instance.activeComponents.Find(c => c.Id == componentId);
        if (component == null)
        {
            CancelCurrentWire();
            return;
        }

        Terminal nearest = GetNearestTerminal(component, fingerTipPosition);
        //if(nearest.IsConnected) return;
        if (nearest == null || nearest == startTerminal || component.terminals[0] == startTerminal || component.terminals[1] == startTerminal)
        {
            CancelCurrentWire();
            return;
        }

        currentLine.SetPosition(1, nearest.transform.position);
        currentWire.endTerminal = nearest;
        currentWire.UpdateCollider();

        nearest.OnConnect(currentWire);
        
        isPlacingWire = false;
        startTerminal = null;
        currentLine = null;
        currentWire = null;
        placingHand = WireHand.None;
        activeFingerTip = null;
    }

    public void CancelCurrentWire()
    {
        if (currentWire != null)
        {
            ObjectPooler.Instance.ReturnToPool(currentWire.gameObject);
        }

        if (startTerminal != null)
        {
            startTerminal.OnDisconnect(currentWire);
        }

        activeWires.Remove(currentWire);
        
        isPlacingWire = false;
        startTerminal = null;
        currentLine = null;
        currentWire = null;
        placingHand = WireHand.None;
        activeFingerTip = null;

    }

    private Terminal GetNearestTerminal(CircuitComponent component, Vector3 fingertip)
    {

        float d0 = Vector3.Distance(fingertip, component.terminals[0].transform.position);
        float d1 = Vector3.Distance(fingertip, component.terminals[1].transform.position);

        Terminal nearest = (d0 < d1) ? component.terminals[0] : component.terminals[1];
        Debug.Log($"d0: {d0} | d1: {d1} | Component: {component.gameObject.name}");
        return (Mathf.Min(d0, d1) <= maxSnapDistance) ? nearest : null;
    }

    public void DeleteWire(Wire wire)
    {
        if (wire == null) return;

        Debug.Log($"[WireManager] Deleting wire {wire.name}");

        // Disconnect terminals
        if (wire.startTerminal != null)
        {
            wire.startTerminal.OnDisconnect(wire);
            wire.startTerminal = null;
        }

        if (wire.endTerminal != null)
        {
            wire.endTerminal.OnDisconnect(wire);
            wire.endTerminal = null;
        }

        activeWires.Remove(wire);

        ObjectPooler.Instance.ReturnToPool(wire.gameObject);
        wire.gameObject.SetActive(false);
    }

    public void InitComponent(Wire wire, int index)
    {
        if (wire == null)
        {
            return;
        }
        wire.id = index;
        allWires.Add(wire);


    }


}




