package no.dnt.sjekkut.network;

import retrofit2.Call;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.http.GET;
import retrofit2.http.Query;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */
public class TripApiSingleton {


    private static TripApiSingleton ourInstance = new TripApiSingleton();

    private final Endpoints api;

    private TripApiSingleton() {
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl("https://dev.nasjonalturbase.no/")
                .client(OkHttpSingleton.getClient())
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = retrofit.create(Endpoints.class);
    }

    public static TripApiSingleton getInstance() {
        return ourInstance;
    }

    public static Endpoints call() {
        return getInstance().api;
    }

    public interface Endpoints {

        @GET("lister/")
        Call<TripList> getTripList(@Query("api_key") String api_key, @Query("fields") String fields);
    }
}
