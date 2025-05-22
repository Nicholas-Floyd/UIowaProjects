using UnityEngine;

public class CircuitPin : MonoBehaviour
{
    public string pinName;           // e.g. "in", "out"
    public string connectedNode = ""; // Filled when connected

    public bool isConnected => !string.IsNullOrEmpty(connectedNode);
}