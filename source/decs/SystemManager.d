module decs.SystemManager;

import std.algorithm;

import decs.EntityManager;
import decs.EventManager;
import decs.System;
import decs.Entity;

import dlib.container.array;

class SystemManager
{
    private System[] m_systems;

    private EventManager m_eventManager;
    private EntityManager m_entityManager;

    public this(EntityManager entityManager, EventManager eventManager)
    {
        this.m_entityManager = entityManager;
        this.m_eventManager = eventManager;
    }

    public void dispose()
    {
        foreach(system; this.m_systems)
        {
            system.dispose();
        }
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

    public void add(System system)
    {
        system.eventManager = this.m_eventManager;
        system.entityManager = this.m_entityManager;

        system.registerComponents();

        this.m_systems ~= system;
    }

    /**
     * An entity has been activated
     * Params:
     *      entity :
     *      entityComponentsMask : entity's components mask
     */
    public void onEntityActivated(ref Entity entity, BoolArray entityComponentsMask)
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
    public void onEntityKilled(ref Entity entity, BoolArray entityComponentsMask)
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