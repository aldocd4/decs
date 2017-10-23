module decs.System;

import decs.Entity;
import decs.Component;
import decs.EventManager;
import decs.EntityManager;

import dnogc.DynamicArray;

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
    public override void registerComponents() nothrow @safe @nogc
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
    public override int[] componentsFilter() nothrow @safe @nogc
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

    protected DynamicArray!(Entity) m_entities;

    protected UpdatePolicy m_updatePolicy;

    protected int[] m_componentsFilter;

    public this(UpdatePolicy updatePolicy = UpdatePolicy.Automatic, in size_t entityPoolSize = 500) nothrow @safe @nogc
    {
        this.m_updatePolicy = updatePolicy;
        this.m_entities = DynamicArray!(Entity)(entityPoolSize);
    }

    public void dispose()
    {
        this.m_entities.dispose();
    }

    /**
     *
     */
    public abstract void update(in float deltaTime);

    /**
     * Registers current system's component if they are not know
     * by the entity manager
     */
    public void registerComponents() nothrow @safe @nogc
    {
        
    }

    /**
     * Returns an static array containing components ids
     */
    @property
    public int[] componentsFilter() nothrow @safe @nogc
    {
        return [];
    }


    /**
     * A new entity that satisfies current system's components filter has been activated
     */
    public void onEntityActivated(ref Entity entity) nothrow @safe @nogc
    {
        this.m_entities.insert(entity);
    }

    /**
     * A new entity that satisfies current system's components filter has been killed
     */
    public void onEntityKilled(in ref Entity entity)
    {
        import std.algorithm;

        auto index = this.m_entities[].countUntil!(e => e.id == entity.id);

        if(index >= 0)
        {
            this.m_entities.remove(index);
        }
    }

    @property
    {
        public ref const(UpdatePolicy) updatePolicy() const pure nothrow @safe @nogc
        {
            return this.m_updatePolicy;
        }

        public void entityManager(EntityManager value) pure nothrow @safe @nogc
        {
            this.m_entityManager = value;
        }

        public void eventManager(EventManager value) pure nothrow @safe @nogc
        {
            this.m_eventManager = value;
        }
    }
}

unittest
{

}