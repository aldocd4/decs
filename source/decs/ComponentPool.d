module decs.ComponentPool;

import dnogc.DynamicArray;

interface IComponentPool
{
    public void dispose();
    public void expand() nothrow @safe @nogc;
    public size_t length() const pure nothrow @safe @nogc;
}

class ComponentPool(T) : IComponentPool
{
    private DynamicArray!T m_components;

    public this(in size_t poolSize) nothrow @safe @nogc
    {
        this.m_components = DynamicArray!T(poolSize);
        this.m_components.length = poolSize;
    }

    public void dispose()
    {
        this.m_components.dispose();
    }

    public void insert()(auto ref T component) nothrow @safe @nogc
    {
        this.m_components.insert(component);
    }

    /**
     * Returns the component at the specified index
     * Params:
     *      index : 
     */
    public T* get(in uint index) pure nothrow @trusted @nogc
    {
        assert(index < this.m_components.length);

        immutable ptr = index * T.sizeof;

        auto data = this.m_components.ptr;

        return cast(T*)data[ptr..(ptr + T.sizeof)];
    }

    /**
     * Sets the value of the component at the specified index
     * Params:
     *      index : 
     *      component :
     */
    public void set(in uint index, ref T component) pure nothrow @safe @nogc
    {
        assert(index < this.m_components.length);

        this.m_components[index] = component;
    }

    /**
     * Expands the pool with an empty value
     */
    public void expand() nothrow @safe @nogc
    {
        this.m_components.insert(T());
    }

    @property
    public size_t length() const pure nothrow @safe @nogc
    {
        return this.m_components.length;
    }
}