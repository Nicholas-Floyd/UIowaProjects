using UnityEngine;

[CreateAssetMenu(fileName = "ComponentDefaults", menuName = "CircuitSim/All Component Defaults")]
public class CircuitComponentDefaults : ScriptableObject
{
    [Header("Resistor")]
    public string resistorDefaultValue = "1kΩ";
    public float resistorResistance = 1000f;

    [Header("Capacitor")]
    public string capacitorDefaultValue = "10µF";
    public float capacitorCapacitance = 0.00001f;

    [Header("FullBattery")]
    public string batteryDefaultValue = "5V";
    public float batteryVoltage = 5f;

    [Header("Inductor")]
    public string inductorDefaultValue = "100µH";
    public float inductorInductance = 0.0001f;

    [Header("Diode")]
    public string diodeDefaultValue = "OFF";
    public bool diodeLit = false;

    [Header("Wire")]
    public Color wireColor = Color.red;

    [Header("Switch")]
    public string switchDefaultValue = "CLOSED";
    public bool switchOpen = false;
}
