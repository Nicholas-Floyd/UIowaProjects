using System.Collections.Generic;
using UnityEngine;
using Xyro.Toolkit.Utility.ObjectPooling;

namespace Xyro.CircuitSimXR.Nick
{
    public class PooledComponentTracker : MonoBehaviour
    {
        public static PooledComponentTracker Instance;

        [System.Serializable]
        public class ComponentSet
        {
            public string tag;
            public List<CircuitComponent> unused = new();
            public List<CircuitComponent> active = new();
        }

        public List<ComponentSet> componentSets = new List<ComponentSet>();
        public List<CircuitComponent> allTrackedComponents = new();

        private int currentID = 0;

        private void Awake()
        {
            Instance = this;
        }
        /*
        public void InitializeTracker()
        {
            currentID = 0;
            componentSets.Clear();
            allTrackedComponents.Clear();

            foreach (var pool in ObjectPooler.Instance.pools)
            {
                string tag = pool.tag;

                if (!ObjectPooler.Instance.poolDictionary.TryGetValue(tag, out Queue<GameObject> poolQueue))
                    continue;

                var set = new ComponentSet { tag = tag };

                foreach (var obj in poolQueue)
                {
                    if (obj == null)
                        continue;

                    var comp = obj.GetComponent<CircuitComponent>();
                    if (comp == null)
                        continue;

                    comp.id = currentID++;
                    set.unused.Add(comp);
                    allTrackedComponents.Add(comp);
                }

                componentSets.Add(set);
            }
        }

        */
        /*
        public void InitializeTracker()
        {
            Debug.Log("[PooledComponentTracker] Initializing tracker...");
            currentID = 0;

            foreach (var pool in ObjectPooler.Instance.pools)
            {
                string tag = pool.tag;
                if (!ObjectPooler.Instance.poolDictionary.ContainsKey(tag)) continue;

                Queue<GameObject> poolQueue = ObjectPooler.Instance.poolDictionary[tag];

                Debug.Log($"[Tracker] Registering {poolQueue.Count} objects from pool '{tag}'");

                var set = new ComponentSet { tag = tag };

                foreach (GameObject obj in poolQueue)
                {
                    var comp = obj.GetComponent<CircuitComponent>();
                    if (comp != null)
                    {
                        comp.ID = currentID++;
                        set.unused.Add(comp);
                        allTrackedComponents.Add(comp);
                        Debug.Log($"[Tracker] Registered {tag} -> {comp.name} (ID: {comp.ID})");
                    }
                    else
                    {
                        Debug.LogWarning($"[Tracker] Object in pool '{tag}' missing CircuitComponent: {obj.name}");
                    }
                }

                componentSets.Add(set);
            }

            Debug.Log($"[PooledComponentTracker] Initialization complete. Total tracked: {allTrackedComponents.Count}");
        }*/


        private void AddToComponentSet(string tag, CircuitComponent comp)
        {
            var set = componentSets.Find(s => s.tag == tag);
            if (set == null)
            {
                set = new ComponentSet { tag = tag };
                componentSets.Add(set);
            }

            set.unused.Add(comp);
        }

        public CircuitComponent ActivateComponent(string tag)
        {
            var set = componentSets.Find(s => s.tag == tag);
            if (set == null || set.unused.Count == 0)
                return null;

            var comp = set.unused[0];
            set.unused.RemoveAt(0);
            set.active.Add(comp);

            return comp;
        }

        public void ReturnToPool(CircuitComponent comp)
        {
            foreach (var set in componentSets)
            {
                if (set.active.Remove(comp))
                {
                    set.unused.Add(comp);
                    return;
                }
            }
        }
    }
}
