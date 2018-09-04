module decs.System;

import decs.Entity;
import decs.Component;
import decs.EventManager;
import decs.EntityManager;

import dlib.container.array;;

/**
 * Mixin template that will help us to generate the components filter
 * for each system.
 */
mixin template ComponentsFilter(Components...)
{
    private Components _components;

    private int[Components.length] m_componentsFilter;

    /**
     * Registers current system's component if they are not know
     * by the entity manager
     */
    public override void registerComponents()
    {
        assert(this.m_entityManager !is null);

        foreach(component; Components)
        {
            this.m_entityManager.checkAndAccomodateComponent!component();
        }
    }

    /**
     * Returns an static array containing components ids
     */
    @property
    public override int[] componentsFilter()
    {
        static bool initialized = false;

        if(!initialized)
        {
            import decs.Component;

            foreach(i, c; Components)
            {
                this.m_componentsFilter[i] = ComponentCounter!(c).getId();
            }

            initialized = true;
        }

        return this.m_componentsFilter;
    }

}

abstract class System
{
    /**
     * Defines if update() function will be automatically
     * called by the system manager or manually by the user
     */
    enum UpdatePolicy
    {
        Automatic,
        Manual
    }

    protected EntityManager m_entityManager;
    protected EventManager m_eventManager;

    enum ENTITY_POOL_SIZE = 500;
    protected DynamicArray!(Entity, ENTITY_POOL_SIZE) m_entities;

    protected UpdatePolicy m_updatePolicy;

    protected int[] m_componentsFilter;

    public this(UpdatePolicy updatePolicy = UpdatePolicy.Automatic)
    {
        this.m_updatePolicy = updatePolicy;
    }

    public void dispose()
    {
        this.m_entities.free();
    }

    /**
     *
     */
    public abstract void update(in float deltaTime);

    /**
     * Registers current system's component if they are not know
     * by the entity manager
     */
    public void registerComponents()
    {
        
    }

    /**
     * Returns an static array containing components ids
     */
    @property
    public int[] componentsFilter()
    {
        return [];
    }


    /**
     * A new entity that satisfies current system's components filter has been activated
     */
    public void onEntityActivated(ref Entity entity)
    {
        this.m_entities.insertBack(entity);
    }

    /**
     * A new entity that satisfies current system's components filter has been killed
     */
    public void onEntityKilled(ref Entity entity)
    {
        import std.algorithm;

        auto index = this.m_entities.data[].countUntil!(e => e.id == entity.id);

        if(index >= 0)
        {
            this.m_entities.removeAt(index);
        }
    }

    @property
    {
        public ref const(UpdatePolicy) updatePolicy() const
        {
            return this.m_updatePolicy;
        }

        public void entityManager(EntityManager value)
        {
            this.m_entityManager = value;
        }

        public void eventManager(EventManager value)
        {
            this.m_eventManager = value;
        }
    }
}

unittest
{

}