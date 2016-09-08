package no.dnt.sjekkut.network;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import org.greenrobot.eventbus.EventBus;

import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.event.ConnectionChangedEvent;
import timber.log.Timber;

/**
 * Created by Espen on 08.09.2016.
 */
public class NetworkStateReceiver extends BroadcastReceiver {

    private static ConnectionChangedEvent previousEvent = null;

    @Override
    public void onReceive(Context context, Intent intent) {
        ConnectionChangedEvent currentEvent = new ConnectionChangedEvent(Utils.isConnected(context));
        boolean postEvent;
        if (previousEvent == null) {
            postEvent = true;
            Timber.i("Send event as there is no previous: %s", currentEvent);
        } else if (currentEvent.isConnected != previousEvent.isConnected) {
            postEvent = true;
            Timber.i("Send event as the previous differed: %s", currentEvent);
        } else if (currentEvent.timestamp - previousEvent.timestamp > 1000L) {
            postEvent = true;
            Timber.i("Send event even if previous matched as it is too old: %s", currentEvent);
        } else {
            postEvent = false;
            Timber.i("Skip event as the previous matched and is too recent: %s", currentEvent);
        }
        if (postEvent) {
            EventBus.getDefault().post(currentEvent);
        }
        previousEvent = currentEvent;
    }
}
