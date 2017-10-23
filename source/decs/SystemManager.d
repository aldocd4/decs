module decs.SystemManager;

import std.algorithm;

import decs.EntityManager;
import decs.EventManager;
import decs.System;
import decs.Entity;

import dnogc.DynamicArray;

class SystemManager
{
    private DynamicArray!(System) m_systems;

    private EventManager m_eventManager;
    private EntityManager m_entityManager;

    public this(EntityManager entityManager, EventManager eventManager) nothrow @safe @nogc
    {
        this.m_systems = DynamicArray!System(50);

        this.m_entityManager = entityManager;
        this.m_eventManager = eventManager;
    }

    public void dispose()
    {
        foreach(system; this.m_systems)
        {
            system.dispose();
        }

        this.m_systems.dispose();
    }

    public void update(in float deltaTime)
    {
        foreach(system; this.m_systems)
        {
            if(system.updatePolicy == System.UpdatePolicy.Automatic)
            {
                system.update(deltaTime);
            }
        }
    }

    public void add(System system) nothrow @safe @nogc
    {
        system.eventManager = this.m_eventManager;
        system.entityManager = this.m_entityManager;

        system.registerComponents();

        this.m_systems.insert(system);
    }

    /**
     * An entity has been activated
     * Params:
     *      entity :
     *      entityComponentsMask : entity's components mask
     */
    public void onEntityActivated(ref Entity entity, BoolArray entityComponentsMask) nothrow @safe @nogc
    {
        // We check if entity's components satisfies each system
        foreach(system; this.m_systems)
        {
            // componentsFilter contains all mandatory components ids for current system
            // We check if each component is known by the entity manager and if its in the
            // entity components mask
            auto componentsFilter = system.componentsFilter;
            
            if(componentsFilter.length && componentsFilter.all!(componentId => componentId < entityComponentsMask.length && entityComponentsMask[componentId]))
            {
                system.onEntityActivated(entity);
            }
        }
    }

    /**
     * An entity has been killed
     * Params:
     *      entity :
     *      entityComponentsMask : entity's components mask
     */
    public void onEntityKilled(in ref Entity entity, BoolArray entityComponentsMask)
    {
        foreach(system; this.m_systems)
        {
            auto componentsFilter = system.componentsFilter;
            
            if(componentsFilter.length && componentsFilter.all!(componentId => componentId < entityComponentsMask.length && entityComponentsMask[componentId]))
            {
                system.onEntityKilled(entity);
            }
        }
    }
}