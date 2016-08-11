package no.dnt.sjekkut.network;

import retrofit2.Call;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.http.GET;
import retrofit2.http.Path;
import retrofit2.http.Query;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */
public enum TripApiSingleton {
    INSTANCE;

    private final TripApi api = new Retrofit.Builder()
            .baseUrl("https://dev.nasjonalturbase.no/")
            .client(OkHttpSingleton.getClient())
            .addConverterFactory(GsonConverterFactory.create(GsonSingleton.custom()))
            .build().create(TripApi.class);

    public static TripApi call() {
        return INSTANCE.api;
    }

    public interface TripApi {

        @GET("lister/")
        Call<TripList> getTripList(@Query("api_key") String api_key, @Query("fields") String fields);

        @GET("lister/{id}/")
        Call<Trip> getTrip(@Path("id") String id, @Query("api_key") String api_key, @Query("fields") String fields, @Query("expand") String expand);
    }
}