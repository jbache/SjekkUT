package no.dnt.sjekkut.network;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 11.08.2016.
 */
public enum GsonSingleton {
    INSTANCE;

    private final Gson adaptersAll = new GsonBuilder()
            .registerTypeAdapter(Place.class, new PlaceDeserializer())
            .registerTypeAdapter(Photo.class, new PhotoDeserializer())
            .registerTypeAdapter(Group.class, new GroupDeserializer())
            .create();

    private final Gson adaptersPhoto = new GsonBuilder()
            .registerTypeAdapter(Photo.class, new PhotoDeserializer())
            .create();


    private final Gson adaptersNone = new GsonBuilder()
            .create();


    public static Gson allAdaptors() {
        return INSTANCE.adaptersAll;
    }


    public static Gson photoAdapter() {
        return INSTANCE.adaptersPhoto;
    }

    public static Gson noAdaptors() {
        return INSTANCE.adaptersNone;
    }
}
