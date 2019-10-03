This project is no longer maintened here. Please check https://github.com/evael-dev/evael-ecs/ for the updated version of this project.

decs
===========

decs is my attempt to build a @nogc D language Entity Component System. 
I'm not really a game dev, im trying to learn how an ECS works so some portions of this code can be inefficients or bug prone.

It's inspired by the following projects : 

* https://github.com/miguelmartin75/anax  => C++ ECS
* https://github.com/jzhu98/star-entity   => D ECS
* https://github.com/claudemr/entitysysd  => D ECS

## How to build

You have to use [dub](https://code.dlang.org/download) to build the project.

Add this project as a dependency to your **dub.json**:

```json
"dependencies": {
    "decs": "~>1.0.3"
}
```

## How to use

### Entity Manager

```cs

import decs;

void main()
{
    auto em = new EntityManager();

    while(game)
    {
        em.update(dt);
    }
    
    // !important!
    em.dispose();
}

```

### Entities

You can create an entity, kill it, invalidate it or activate it (still need some work here). 

```cs
auto entity = em.createEntity();

// Notifies all systems that a new entity is alive
entity.activate();

// Entity is still alive but will be invalid in current scope
entity.invalidate();

// Poor entity :<
entity.kill();
```

### Components

A component must be represented as a struct.

```cs
struct PositionComponent
{
    float x, y, z;
}
```

You can add a component to an entity :

```cs
// add
entity.add!PositionComponent(1, 2, 3);

// update (its handled as a pointer)
entity.get!PositionComponent().y = 50;

// check
if(entity.has!PositionComponent())
{
    // ...
}
```
### Systems

A system must be a class that inherits **decs.System**.

```cs
class MovementSystem : System
{
    public void update(in float delta)
    {

    }
}
```
There is 2 ways to query entities from your system : 

* 1 => Using entity manager **entities!(components...)** method
* 2 => Using the mixin template **mixin ComponentsFilter!(components...);**


If you provide a components filter, when an entity is activated, it will be automatically added to the systems whose filters match her components.

```cs
class MovementSystem : System
{
    // option 2
    mixin ComponentsFilter!(PositionComponent);

    public void update(in float deltaTime)
    {
        // option 1
        auto entities = this.m_entityManager.entities!(PositionComponent);

        // option 2 (should be more efficient)
        foreach(entity; this.m_entities)
        {

        }
    }
}
```
System's update method will be called automatically by the entity manager in the main loop. If you want to handle the update manually, you can set the **System.UpdatePolicy** to manual :

```cs
class MovementSystem : System
{
    public this()
    {
        super(System.UpdatePolicy.Manual);
    }
}

// ...

while(game)
{
    em.update(dt);

    // you have to call it manually (before or after the em.update call)
    myMovementSystem.update(dt);
}
```

### Events

A receiver is a class that implements **Receiver(EventType)** interface.

```cs
// An event must be a struct
struct MovementEvent
{
    Entity target;
}

// The receiver
class CameraSystem : Receiver!MovementEvent
{
    /**
     * Movement event received from a system
     */
    public void receive(ref MovementEvent event)
    {
        // follow event.entity...
    }
}

// Subscribe to events
void main()
{
    auto cameraSys = new CameraSystem();

    auto em = new EntityManager();
    em.subscribeToEvent!MovementEvent(cameraSys);
}
```

You can send events from systems by using the **m_eventManager.emit** method.

```cs
// Sending an event from the MovementSystem
class MovementSystem : Receiver!MovementEvent
{
    public void update(in float deltaTime)
    {
        foreach(entity; this.m_entities)
        {
            this.m_eventManager.emit(MovementEvent(entity));
        }
    }
}
```

## TODOs

* Add **@Component** and **@Event** UDAs
* Add an example project
* Improve this readme
* DOCS !
