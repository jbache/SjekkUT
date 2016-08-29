package no.dnt.sjekkut.network;

import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonParseException;

import java.lang.reflect.Type;
import java.text.ParseException;
import java.util.Date;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 29.08.2016.
 */
public class DateSerializer implements JsonDeserializer<Date> {
    @Override
    public Date deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
        String dateToParse = json.getAsString();
        try {
            return DateSingleton.getDateFormat().parse(dateToParse);
        } catch (ParseException ignored) {
        }
        throw new JsonParseException("Unparseable date: " + dateToParse);
    }
}