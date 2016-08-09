package no.dnt.sjekkut.network;

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
public class LoginApiSingleton {

    public static final String OAUTH2_REDIRECT_URL = "https://localhost/callback";
    public static final String API_MEDLEMSDATA = "api/oauth/medlemsdata/";
    public static final String API_TOKEN = "o/token/";

    private static LoginApiSingleton ourInstance = new LoginApiSingleton();

    private final Endpoints api;

    private LoginApiSingleton() {
        Retrofit retrofit = new Retrofit.Builder()
                .baseUrl("https://www.dnt.no/")
                .client(OkHttpSingleton.getClient())
                .addConverterFactory(GsonConverterFactory.create())
                .build();
        api = retrofit.create(Endpoints.class);
    }

    public static LoginApiSingleton getInstance() {
        return ourInstance;
    }

    public static Endpoints call() {
        return getInstance().api;
    }

    public interface Endpoints {

        @FormUrlEncoded
        @POST(API_TOKEN)
        Call<AuthorizationToken> getToken(@Field("grant_type") String grant_type,
                                          @Field("code") String code,
                                          @Field("redirect_uri") String redirect_uri,
                                          @Field("client_id") String client_id,
                                          @Field("client_secret") String client_secret);

        @FormUrlEncoded
        @POST(API_TOKEN)
        Call<AuthorizationToken> refreshToken(@Field("grant_type") String grant_type,
                                              @Field("refresh_token") String refresh_token,
                                              @Field("redirect_uri") String redirect_uri,
                                              @Field("client_id") String client_id,
                                              @Field("client_secret") String client_secret);

        @GET(API_MEDLEMSDATA)
        Call<MemberData> getMember(@Header("Authorization") String authorization);
    }
}
