package no.dnt.sjekkut.event;

/**
 * Created by Espen on 08.09.2016.
 */
public class ConnectionChangedEvent {

    public long timestamp;
    public boolean isConnected;

    public ConnectionChangedEvent(boolean isConnected) {
        this.timestamp = System.currentTimeMillis();
        this.isConnected = isConnected;
    }

    @Override
    public String toString() {
        String result = isConnected ? "Connected" : "Disconnected";
        result += " timestamp " + timestamp;
        return result;
    }
}
