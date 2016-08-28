package no.dnt.sjekkut.network;

import retrofit2.Call;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.POST;
import retrofit2.http.Path;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */
public enum CheckinApiSingleton {
    INSTANCE;

    private final CheckinApi api = new Retrofit.Builder()
            .baseUrl("https://sjekkut.app.dnt.no/v2/")
            .client(OkHttpSingleton.getClient())
            .addConverterFactory(GsonConverterFactory.create(GsonSingleton.allAdaptors()))
            .build().create(CheckinApi.class);

    public static CheckinApi call() {
        return INSTANCE.api;
    }

    public interface CheckinApi {

        @GET("steder/{id}/logg")
        Call<PlaceCheckinList> getPlaceCheckinList(@Path("id") String placeId);

        @GET("steder/{id}/stats")
        Call<PlaceCheckinStats> getPlaceCheckinStats(@Path("id") String placeId);

        @GET("brukere/{id}")
        Call<UserCheckins> getUserCheckins(@Path("id") String userId);

        @POST("steder/{id}/besok")
        Call<CheckinResult> postPlaceCheckin(@Header("X-User-Id") String userId, @Header("X-User-Token") String userToken, @Path("id") String placeId, @Body CheckinLocation location);
    }
}
