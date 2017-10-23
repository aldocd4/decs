module decs.EventManager;

import dnogc.DynamicArray;

interface IReceiver
{

}

interface Receiver(Event) : IReceiver
{
    public void receive(ref Event event);
}

private alias ReceiverArray = DynamicArray!(IReceiver);

class EventManager
{
    private DynamicArray!(ReceiverArray) m_receivers;

    public this() pure nothrow @safe @nogc
    {

    }

    public void dispose()
    {
        foreach(ref receiver; this.m_receivers)
        {
            receiver.dispose();
        }

        this.m_receivers.dispose();
    }

    /**
     * Subscribes to an event
     */
    public void subscribe(Event)(Receiver!Event receiver) nothrow @trusted
    {
        immutable eventId = EventCounter!(Event).getId();

        // We check if we added this type of event
        if(eventId >= this.m_receivers.length)
        {
            // No, we add it
            auto receivers = ReceiverArray();
            receivers.insert(receiver);

            this.m_receivers.insert(receivers);
        }
        else this.m_receivers[eventId].insert(receiver);
    }

    /**
     * Notifies to all receivers a new event
     */
    public void emit(Event)(Event event)
    {
        immutable eventId = EventCounter!(Event).getId();

        if(eventId < this.m_receivers.length)
        {
            foreach(receiver; this.m_receivers[eventId])
            {
                auto r = cast(Receiver!Event) receiver;
                r.receive(event);
            }
        }
    }
}

struct GlobalEventCounter
{
    static uint counter = 0;
}

/**
 * Helper used to get an unique id per component
 */
struct EventCounter(Event)
{
    private GlobalEventCounter globalEventCounter;

    public static uint getId() nothrow @safe @nogc
    {
        static uint counter = -1;

        if(counter == -1)
        {
            counter = globalEventCounter.counter;
            globalEventCounter.counter++;
        }

        return counter;
    }
}
