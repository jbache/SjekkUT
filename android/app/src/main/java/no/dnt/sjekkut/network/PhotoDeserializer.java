package no.dnt.sjekkut.network;

import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonParseException;

import java.lang.reflect.Type;

import timber.log.Timber;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 11.08.2016.
 */
public class PhotoDeserializer implements JsonDeserializer<Photo> {
    @Override
    public Photo deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
        if (json.isJsonObject()) {
            return GsonSingleton.noAdaptors().fromJson(json.getAsJsonObject(), Photo.class);
        } else {
            return new Photo(json.getAsString());
        }
    }
}
