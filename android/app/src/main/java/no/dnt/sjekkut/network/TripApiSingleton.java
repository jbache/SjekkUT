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

    public static final String PROJECT_FIELDS = "steder,geojson,bilder,img,grupper,lenker,start,stopp,fylke,kommune";
    public static final String PROJECT_EXPAND = "steder,bilder,grupper";
    public static final String PLACE_EXPAND = "bilder";
    public static final String PROJECTLIST_FIELDS = "steder,bilder,geojson,grupper";

    private final TripApi api = new Retrofit.Builder()
            .baseUrl("https://dev.nasjonalturbase.no/")
            .client(OkHttpSingleton.getClient())
            .addConverterFactory(GsonConverterFactory.create(GsonSingleton.allAdaptors()))
            .build().create(TripApi.class);

    public static TripApi call() {
        return INSTANCE.api;
    }

    public interface TripApi {

        @GET("lister/")
        Call<ProjectList> getProjectList(@Query("api_key") String api_key, @Query("fields") String fields);

        @GET("lister/{id}/")
        Call<Project> getProject(@Path("id") String id, @Query("api_key") String api_key, @Query("fields") String fields, @Query("expand") String expand);

        @GET("steder/{id}/")
        Call<Place> getPlace(@Path("id") String id, @Query("api_key") String api_key, @Query("expand") String expand);
    }
}
