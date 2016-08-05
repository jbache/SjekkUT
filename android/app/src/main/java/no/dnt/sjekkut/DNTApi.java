package no.dnt.sjekkut;

import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Call;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.http.Field;
import retrofit2.http.FormUrlEncoded;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.POST;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */
public class DNTApi {

    private static DNTApi ourInstance = new DNTApi();

    private final Endpoints api;

    private DNTApi() {
        HttpLoggingInterceptor interceptor = new HttpLoggingInterceptor();
        if (BuildConfig.DEBUG) {
            interceptor.setLevel(HttpLoggingInterceptor.Level.BODY);
        } else {
            interceptor.setLevel(HttpLoggingInterceptor.Level.NONE);
        }
        OkHttpClient httpClient = new OkHttpClient.Builder().addInterceptor(interceptor).build();

        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl("https://www.dnt.no/")
                .client(httpClient)
                .addConverterFactory(GsonConverterFactory.create())
                .build();

        api = retrofit.create(Endpoints.class);
    }

    public static DNTApi getInstance() {
        return ourInstance;
    }

    public static Endpoints call() {
        return getInstance().api;
    }

    public interface Endpoints {

        @FormUrlEncoded
        @POST("o/token/")
        Call<AuthorizationToken> getToken(@Field("grant_type") String grant_type,
                                          @Field("code") String code,
                                          @Field("redirect_uri") String redirect_uri,
                                          @Field("client_id") String client_id,
                                          @Field("client_secret") String client_secret);

        @FormUrlEncoded
        @POST("o/token/")
        Call<AuthorizationToken> refreshToken(@Field("grant_type") String grant_type,
                                              @Field("refresh_token") String refresh_token,
                                              @Field("redirect_uri") String redirect_uri,
                                              @Field("client_id") String client_id,
                                              @Field("client_secret") String client_secret);

        @GET("api/oauth/medlemsdata/")
        Call<MemberData> getMember(@Header("Authorization") String authorization);
    }
}
