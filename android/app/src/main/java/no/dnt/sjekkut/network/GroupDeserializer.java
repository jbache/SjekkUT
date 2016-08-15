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
public class GroupDeserializer implements JsonDeserializer<Group> {
    @Override
    public Group deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
        if (json.isJsonObject()) {
            return GsonSingleton.noAdaptors().fromJson(json.getAsJsonObject(), Group.class);
        } else {
            return new Group(json.getAsString());
        }
    }
}
