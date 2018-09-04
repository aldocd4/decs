module decs.Entity;

import decs.EntityManager;

struct Entity
{
    private EntityManager m_em;
    private Id m_id = Id.Invalid;

    public this(EntityManager em)
    {
        this.m_em = em;
        this.m_id = Id.Invalid;
    }

    public this()(EntityManager em, in auto ref Id id)
    {
        this.m_em = em;
        this.m_id = id;
    }

    /**
     * Adds component for this entity
     */
    public void add(C)(C component)
    {
        assert(this.m_em !is null);

        this.m_em.addComponent!C(this.m_id, component);
    }

    /**
     * Returns component of this entity
     */
    public C* get(C)()
    {
        assert(this.m_em !is null);

        return this.m_em.getComponent!C(this.m_id);
    }

    /**
     * Checks if this entity own a specific component
     */
    public bool has(C)()
    {
        assert(this.m_em !is null);

        return this.m_em.hasComponent!C(this.m_id);
    }

    public void kill()
    {
        if (this.m_em !is null)
        {
            this.m_em.killEntity(this.m_id);
        }

        this.m_em = null;
        this.m_id = Id.Invalid;
    }

    public void activate()
    {
        assert(this.m_em !is null);

        this.m_em.activateEntity(this);
    }

    /**
     * Invalidates current entity, but its still a living entity
     */
    public void invalidate()
    {
        this.m_id.state = Id.State.Invalid;
    }

    public bool isValid() const
    {
        return this.m_id.state != Id.State.Invalid;
    }

    public int opCmp(in ref Entity rhs) const
	{
        return this.m_id.opCmp(rhs.id);
	}

    @property
    public ref const(Id) id() const
    {
        return this.m_id;
    }
}

struct Id
{
    public enum State
    {
        Valid,
        Invalid
    }

    static immutable Id Invalid = Id();

    private size_t m_index;

    private State m_state = State.Invalid;

    public this(in size_t index)
    {
        this.m_index = index;
        this.m_state = State.Valid;
    }

    public bool opEquals()(in auto ref Id rhs) const
    {
        return this.m_index == rhs.index;
    }

    public int opCmp(in ref Id rhs) const
    {
        if (this.m_index > rhs.index)
        {
            return 1;
        }
        else if (this.m_index == rhs.index)
        {
            return 0;
        }
        else
        {
            return -1;
        }
    }

    @property
    {
        public size_t index() const
        {
            return this.m_index;
        }

        public void index(in size_t value)
        {
            this.m_index = value;
            this.m_state = State.Valid;
        }

        public State state() const
        {
            return this.m_state;
        }

        public void state(in State value)
        {
            this.m_state = value;
        }
    }
}
