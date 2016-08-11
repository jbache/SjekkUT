package no.dnt.sjekkut.network;

import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonParseException;

import java.lang.reflect.Type;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 11.08.2016.
 */
public class PlaceDeserializer implements JsonDeserializer<Place> {
    @Override
    public Place deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
        if (json.isJsonObject()) {
            return GsonSingleton.plain().fromJson(json.getAsJsonObject(), Place.class);
        } else {
            return new Place(json.getAsString());
        }
    }
}
