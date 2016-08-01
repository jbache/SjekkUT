package no.dnt.sjekkut;

import android.app.Activity;
import android.location.Location;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonParseException;
import com.squareup.okhttp.OkHttpClient;

import org.apache.http.HttpStatus;

import java.lang.ref.WeakReference;
import java.lang.reflect.Type;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

import retrofit.Callback;
import retrofit.ErrorHandler;
import retrofit.RestAdapter;
import retrofit.RetrofitError;
import retrofit.client.OkClient;
import retrofit.converter.GsonConverter;
import retrofit.http.Body;
import retrofit.http.GET;
import retrofit.http.Header;
import retrofit.http.Headers;
import retrofit.http.POST;
import retrofit.http.Path;

/**
 * Copyright Den Norske Turistforening 2015
 *
 * Created by espen on 06.02.2015.
 */
public class OppturApi {

    private static final String API_URL = "https://dntopptur.appspot.com";

    public interface OppturService {

        @Headers("Content-Type: application/json")
        @GET("/mountains/")
        void listMountains(Callback<List<Mountain>> callback);

        @Headers("Content-Type: application/json")
        @GET("/checkins/")
        void listCheckins(@Header("device-id") String deviceID, Callback<List<Checkin>> callback);

        @Headers("Content-Type: application/json")
        @POST("/mountains/{id}/checkin")
        void checkinToMountain(@Path("id") long mountainID, @Header("device-id") String deviceID, @Body CheckinBody body, Callback<Checkin> callback);

        @Headers("Content-Type: application/json")
        @GET("/mountains/{id}/stats")
        void getMountainStatistics(@Path("id") long mountainID, @Header("device-id") String deviceID, Callback<Checkin.Statistics> callback);

        @Headers("Content-Type: application/json")
        @GET("/challenges/")
        void listChallenges(@Header("device-id") String deviceID, Callback<List<Challenge>> callback);

        @Headers("Content-Type: application/json")
        @POST("/challenges/{id}/join")
        void joinChallenge(@Path("id") long challengeID, @Header("device-id") String deviceID, Callback<Challenge> callback);

        @Headers("Content-Type: application/json")
        @POST("/users/")
        void registerUser(@Header("device-id") String deviceID, @Body User user, Callback<User> callback);
    }

    protected static class CheckinBody {

        final Mountain.LocationContainer location = new Mountain.LocationContainer();

        CheckinBody(Location location) {
            this.location.Lat = location.getLatitude();
            this.location.Lng = location.getLongitude();
        }
    }

    private static final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US);
    static {
        dateFormat.setTimeZone(TimeZone.getTimeZone("UTC"));
    }

    private static class DateDeserializer implements JsonDeserializer<Date> {

        @Override
        public Date deserialize(JsonElement jsonElement, Type typeOF, JsonDeserializationContext context) throws JsonParseException {
            String dateToParse = jsonElement.getAsString();
            try {
                return dateFormat.parse(dateToParse);
            } catch (ParseException ignored) {
                // ignore on purpose
            }
            throw new JsonParseException("Unparseable date: \"" + dateToParse);
        }
    }

    private static final Gson sGson = new GsonBuilder()
            .registerTypeAdapter(Date.class, new DateDeserializer())
            .create();

    private static final OkHttpClient sHttpClient = new OkHttpClient();

    static {
        sHttpClient.setConnectTimeout(10, TimeUnit.SECONDS);
        sHttpClient.setReadTimeout(10, TimeUnit.SECONDS);
        sHttpClient.setWriteTimeout(10, TimeUnit.SECONDS);
    }

    public static WeakReference<Activity> sActivityReference;

    public static final ErrorHandler sErrorHandler = new ErrorHandler() {

        @Override
        public Throwable handleError(RetrofitError cause) {
            int error = 0;
            switch (cause.getKind()) {
                case NETWORK:
                    error = R.string.network_error;
                    break;
                case HTTP:
                    if (cause.getResponse().getStatus() >= HttpStatus.SC_INTERNAL_SERVER_ERROR)
                        error = R.string.http_error;
                    break;
                case CONVERSION:
                    error = R.string.conversion_error;
                    break;
            }
            if (error != 0 && sActivityReference.get() != null) {
                final Activity activity = sActivityReference.get();
                final String errorString = activity.getString(error);
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        Utils.showToast(activity, errorString);
                    }
                });
            }
            return cause;
        }
    };

    private static final RestAdapter REST_ADAPTER = new RestAdapter.Builder()
            .setErrorHandler(sErrorHandler)
            .setClient(new OkClient(sHttpClient))
            .setEndpoint(API_URL)
            .setLogLevel(RestAdapter.LogLevel.FULL)
            .setConverter(new GsonConverter(sGson))
            .build();

    private static final OppturService OPPTUR_SERVICE = REST_ADAPTER.create(OppturService.class);

    public static OppturService getService() {
        return OPPTUR_SERVICE;
    }
}
