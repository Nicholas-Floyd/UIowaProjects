
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Xyro.CircuitSimXR.Alex
{
    [System.Serializable]
    public enum GameState
    {
        LOADING,
        MENU,
        COMPONENT_STATE,
        WIRE_STATE,
        SIMULATION

    }
    [System.Serializable]
    public enum GameSubstate
    {
        MENU,
        COMPONENT_PLACE,
        COMPONENT_EDIT,
        WIRE_PLACE,
        WIRE_EDIT,
        SIMULATION
    }
    [System.Serializable]
    public enum ComponentState
    {
        COMPONENT_PLACE,
        COMPONENT_EDIT, 
        COMPONENT_DELETE
    }
    [System.Serializable]
    public enum WireState
    {
        WIRE_PLACE,
        WIRE_EDIT,
        WIRE_DELETE
    }

}
