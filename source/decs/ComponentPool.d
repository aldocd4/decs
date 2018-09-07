module decs.ComponentPool;

import dlib.container.array;

interface IComponentPool
{
    public void dispose();
    public void expand();
    public size_t length();
}

class ComponentPool(T) : IComponentPool
{
    private DynamicArray!(T) m_components;

    public this(in size_t poolSize)
    {
        while (this.m_components.length < poolSize)
        {
            this.expand();
        }
    }

    public void dispose()
    {
        this.m_components.free();
    }

    public void insert()(auto ref T component)
    {
        this.m_components.insertBack(component);
    }

    /**
     * Returns the component at the specified index
     * Params:
     *      index : 
     */
    public T* get(in uint index)
    {
        assert(index < this.m_components.length);

        return &this.m_components.data[index];
    }

    /**
     * Sets the value of the component at the specified index
     * Params:
     *      index : 
     *      component :
     */
    public void set(in uint index, ref T component)
    {
        assert(index < this.m_components.length);

        this.m_components[index] = component;
    }

    /**
     * Expands the pool with an empty value
     */
    public void expand()
    {
        this.m_components.insertBack(T());
    }

    @property
    public size_t length()
    {
        return this.m_components.length;
    }
}