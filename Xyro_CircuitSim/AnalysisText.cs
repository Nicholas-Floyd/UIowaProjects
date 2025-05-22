

using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using Xyro.CircuitSimXR.Alex;
using Xyro.CircuitSimXR.Phil;
using Xyro.CircuitSimXR.Nick;
using Xyro.Toolkit.Core;



public class AnalysisText : MonoBehaviour
{
    public Dictionary<int, ComponentResultDisplay> componentDict = new Dictionary<int, ComponentResultDisplay>();

    public TMP_Text totalVoltageText;
    public TMP_Text totalResistanceText;
    public TMP_Text totalCurrentText;
    public TMP_Text voltageMagText;
    public TMP_Text currentMagText;
    public TMP_Text ownResistanceText;
    public TMP_Text minPathResistanceText;
    public TMP_Text parallelCombinedResistanceText;
    public TMP_Text phaseAngleText;
    public TMP_Text totalText;



    private const string DASH = "-";
    private const string VOLTAGE = " V";
    private const string RESISTANCE = " Ω";
    private const string ANGLE = "°";
    private const string AMPERE = " A";





    private void Awake()
    {
        SetNotAvailableData();
    }

    public void SetNotAvailableData()
    {
        totalVoltageText.text = DASH;
        totalResistanceText.text = DASH;
        totalCurrentText.text = DASH;
        voltageMagText.text = DASH;
        currentMagText.text = DASH;
        minPathResistanceText.text = DASH;
        parallelCombinedResistanceText.text = DASH;
        phaseAngleText.text = DASH;
        ownResistanceText.text = DASH;
        totalText.text = "";


    }


    //Call method when simulate button is hit
    public void UpdateTotalText()
    {
        if (!AnalyzeFunctions.Instance.HasDCResult())
        {
            totalText.text = "No DC result available.";
            totalVoltageText.text = DASH;
            totalResistanceText.text = DASH;
            totalCurrentText.text = DASH;
            return;
        }
        totalText.text = "";

        var result = AnalyzeFunctions.Instance.inspectorResults[0];
        totalVoltageText.text = FormatWithSIUnit(result.totalVoltage, "V");
        totalResistanceText.text = FormatWithSIUnit(result.totalResistanceOrImpedance, "Ω");
        totalCurrentText.text = FormatWithSIUnit(result.totalCurrent, "A");

        componentDict.Clear();
        foreach (var comp in result.componentResults)
        {
            componentDict[comp.ComponentId] = comp;
        }
    }


    private void OnEnable()
    {
        GameManager.Instance.onSimulateComponent += UpdateComponentText;
        GameManager.Instance.onGameStateChange += HandleGameStateChange;
    }

    private void HandleGameStateChange(GameState gameState)
    {

        if(gameState != GameState.SIMULATION)
        {
            voltageMagText.text = DASH;
            currentMagText.text = DASH;
            minPathResistanceText.text = DASH;
            parallelCombinedResistanceText.text = DASH;
            phaseAngleText.text = DASH;
            componentDict.Clear();
        }
        else
        {
            var componentsToDelete = new List<CircuitComponent>();

            foreach (var comp in CircuitManager.Instance.activeComponents)
            {
                if (!comp.terminals[0].IsConnected && !comp.terminals[1].IsConnected)
                {
                    componentsToDelete.Add(comp);
                }
            }

            foreach (var comp in componentsToDelete)
            {
                comp.DeleteComponent();
            }

            AnalyzeFunctions.Instance.RunDCAnalysis();
            UpdateTotalText();
        }
    }

    private void UpdateComponentText(int id)
    {
        if (componentDict.TryGetValue(id, out var component))
        {
            voltageMagText.text = FormatWithSIUnit(component.VoltageMagnitude, "V");
            currentMagText.text = FormatWithSIUnit(component.CurrentMagnitude, "A");
            ownResistanceText.text = FormatWithSIUnit(component.OwnResistance, "Ω");
            minPathResistanceText.text = FormatWithSIUnit(componentDict[id].MinPathResistance, "Ω");
            parallelCombinedResistanceText.text = FormatWithSIUnit(componentDict[id].ParallelCombinedResistance, "Ω");
            phaseAngleText.text = component.PhaseAngleDegrees.ToString("F3") + "°";
        }
        else
        {
            voltageMagText.text = DASH;
            currentMagText.text = DASH;
            ownResistanceText.text = DASH;
            minPathResistanceText.text = DASH;
            parallelCombinedResistanceText.text = DASH;
            phaseAngleText.text = DASH;
        }
    }


    private string FormatWithSIUnit(double value, string unit)
    {
        double absValue = Math.Abs(value);
        string sign = value < 0 ? "-" : "";

        if (absValue >= 1e9)
            return sign + (absValue / 1e9).ToString("F3") + " G" + unit;  // giga
        else if (absValue >= 1e6)
            return sign + (absValue / 1e6).ToString("F3") + " M" + unit;  // mega
        else if (absValue >= 1e3)
            return sign + (absValue / 1e3).ToString("F3") + " k" + unit;  // kilo
        else if (absValue >= 1)
            return sign + absValue.ToString("F3") + " " + unit;           // base
        else if (absValue >= 1e-3)
            return sign + (absValue * 1e3).ToString("F3") + " m" + unit; // milli
        else if (absValue >= 1e-6)
            return sign + (absValue * 1e6).ToString("F3") + " μ" + unit; // micro
        else if (absValue >= 1e-9)
            return sign + (absValue * 1e9).ToString("F3") + " n" + unit; // nano
        else
            return sign + "0 " + unit; // fallback for near zero
    }



}

