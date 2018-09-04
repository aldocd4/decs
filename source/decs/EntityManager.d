module decs.EntityManager;

debug import std.stdio;

import dlib.container.array;
import dlib.core.memory;

import decs.System;
import decs.SystemManager;
import decs.EventManager;
import decs.Entity;
import decs.Component;
import decs.ComponentPool;

alias BoolArray = DynamicArray!bool;

class EntityManager
{
    enum COMPONENTS_POOL_SIZE = 50;
    /// [ Component1[entity1, entity2...] , Component2[entity1, entity2...] ...]
    private DynamicArray!(IComponentPool, COMPONENTS_POOL_SIZE) m_components;

    /// [ Entity1[component1, component2...] , Entity2[component1, component2...] ...]
    private DynamicArray!(BoolArray) m_componentMasks;

    private DynamicArray!size_t m_freeIds;
    private size_t m_currentIndex;

    private SystemManager m_systemManager;
    private EventManager m_eventManager;

    public this()
    {
        this.m_eventManager = new EventManager();
        this.m_systemManager = new SystemManager(this, this.m_eventManager);
    }

    public void dispose()
    {
        foreach(pool; this.m_components)
        {
            pool.dispose();
        }

        foreach(mask; this.m_componentMasks)
        {
            mask.free();
        }

        this.m_components.free();
        this.m_componentMasks.free();
        this.m_freeIds.free();
        this.m_systemManager.dispose();
        this.m_eventManager.dispose();

        Delete(this.m_systemManager);
        Delete(this.m_eventManager);
    }

    public void update(in float deltaTime)
    {
        this.m_systemManager.update(deltaTime);
    }

    /**
     * Adds a system
     * Params:
     *      system :
     */
    public void addSystem(System system)
    {
        this.m_systemManager.add(system);
    }

    /**
     * Subscribes to an event
     * Params:
     *      receiver :
     */
    public void subscribeToEvent(Event)(Receiver!Event receiver)
    {
        this.m_eventManager.subscribe(receiver);
    }

    /**
     * Creates an entity
     */
    public Entity createEntity()
    {
        auto id = Id();

        if(this.m_freeIds.length() == 0)
        {
            id.index = this.m_currentIndex;

            this.accomodateEntity(id.index);
        }
        else
        {
            id.index = this.m_freeIds[this.m_freeIds.length() - 1];
            this.m_freeIds.removeBack(1);
        }

        return Entity(this, id);
    }

    public void accomodateEntity(in size_t index)
    {
        immutable nextIndex = index + 1;

        if(index >= this.m_currentIndex)
        {
            // Expand component mask array
            if(this.m_componentMasks.length < nextIndex)
            {
                auto mask = BoolArray();

                for (int i = 0; i < this.m_components.length(); i++)
                {
                    mask.insertBack(false);
                }

                this.m_componentMasks.insertBack(mask);
            }

            // Expand all component arrays
            if(this.m_components.length > 0 && this.m_components[0].length < nextIndex)
            {
                foreach(componentPool; this.m_components)
                {
                    componentPool.expand();
                }
            }
        }

        this.m_currentIndex = nextIndex;
    }

    /**
     * Activates an entity
     * Systems are notified that a new entity has been activated
     */
    public void activateEntity(ref Entity entity)
    {
        assert(entity.isValid, "Entity is invalid");

        this.m_systemManager.onEntityActivated(entity, this.m_componentMasks[entity.id.index]);
    }

    /**
     * Kills an entity
     * Systems are notified that a new entity has been killed
     */
    public void killEntity(in ref Id id)
    {
        immutable index = id.index;

        this.m_freeIds.insertBack(id.index);

        // Notifying systems that an entity has been killed
        auto entity = Entity(this, id);
        this.m_systemManager.onEntityKilled(entity, this.m_componentMasks[index]);

        this.m_componentMasks[index].data[] = false;
    }

    /**
     * Adds component for an entity
     * Params:
     *		id :
     *		component :
     */
    public void addComponent(C)(in ref Id id, C component)
    {
        immutable componentId = this.checkAndAccomodateComponent!C();

        // Adding the component in the pool
        auto pool = cast(ComponentPool!C)this.m_components[componentId];

        assert(pool !is null, "pool is null for component " ~ C.stringof);

        pool.set(id.index, component);

        // Set the mask
        // TODO : dlib.array bug ? I need to type .data before accessing mask
        this.m_componentMasks.data[id.index][componentId] = true;
    }

    /**
     * Checks if a component is already known by the entity manager
     */
    public int checkAndAccomodateComponent(C)()
    {
        immutable componentId = ComponentCounter!(C).getId();

        // We check if that component is known
        if(this.m_components.length <= componentId)
        {
            // No
            this.accomodateComponent!C(componentId);
        }

        return componentId;
    }

    /**
     * Accomodates a component
     * Params:
     *		componentId :
     */
    private void accomodateComponent(C)(in int componentId)
    {
        // Expanding component pool
        auto componentPool = New!(ComponentPool!C)(this.m_currentIndex);
        this.m_components.insertBack(componentPool);

        // Expanding all components masks to include a new component
        if(this.m_componentMasks.length > 0 && this.m_componentMasks[0].length <= componentId)
        {
            foreach(ref componentMask; this.m_componentMasks)
            {
                componentMask.insertBack(false);
            }
        }
    }

    /**
     * Returns component of type C for a specific entity
     * Params:
     *		id :
     */
    public C* getComponent(C)(in ref Id id)
    {
        immutable componentId = this.checkAndAccomodateComponent!C();

        auto pool = cast(ComponentPool!C)this.m_components[componentId];
        return pool.get(id.index);
    }

    /**
     * Checks if an entity own a specific component
     */
    public bool hasComponent(C)(in ref Id id)
    {
        immutable componentId = this.checkAndAccomodateComponent!C();

        return this.m_componentMasks[id.index][componentId] != false;
    }

    /**
     * Returns a range containing entities with the specified components
     */
    auto entities(Components...)()
    {
        import std.algorithm;
        import std.array;

        if(this.m_components.length == 0)
        {
            return this[].array;
        }

        auto mask = this.getComponentsMask!Components();

        bool hasComponents(in Entity entity)
        {
            // We loop all components for current range entity
            // and verify if he own the components
            int i = 0;
            foreach(bitValue; this.m_componentMasks[entity.id.index])
            {
                if(mask[i++] == true && bitValue == false)
                {
                    return false;
                }
            }

            return true;
        }

        auto entities = this[].filter!(hasComponents)().array;

        // @nogc killer
        mask.free();

        return entities;
    }

    /**
     * Returns a mask with the specified components
     */
    public BoolArray getComponentsMask(Components...)()
    {
        auto mask = BoolArray();

        for (int i = 0; i < this.m_components.length(); i++)
        {
            mask.insertBack(false);
        }

        foreach(component; Components)
        {
            immutable componentId = ComponentCounter!(component).getId();

            // We check if that component is known
            if(this.m_components.length <= componentId)
            {
                // Nop, we accomodate it
                this.accomodateComponent!component(componentId);

                mask.insertBack(true);
            }
            else
            {
                mask[componentId] = true;
            }
        }

        return mask;
    }

    public Entity getEntityByIndex(in uint index)
    {
        return Entity(this, Id(index));
    }

    public EntityRange opSlice()
    {
        return EntityRange(this);
    }
}

struct EntityRange
{
    private EntityManager m_em;

    private uint m_index;

    private this(EntityManager em, in uint index = 0) 
    {
        this.m_em = em;
        this.m_index = index;
    }

    public void popFront()
    {
        this.m_index++;
    }

    public EntityRange save()
    {
        return EntityRange(this.m_em, this.m_index);
    }

    @property
    {
        public size_t length() const
        {
            return this.m_em.m_currentIndex;
        }

        public bool empty() const
        {
            return this.m_index >= this.m_em.m_currentIndex;
        }

        public Entity front()
        {
            return this.m_em.getEntityByIndex(this.m_index);
        }
    }
}