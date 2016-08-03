package no.dnt.sjekkut;

import retrofit.Callback;
import retrofit.RestAdapter;
import retrofit.http.Field;
import retrofit.http.FormUrlEncoded;
import retrofit.http.GET;
import retrofit.http.Header;
import retrofit.http.POST;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */
public class DNTApi {

    private static DNTApi ourInstance = new DNTApi();

    private final Endpoints api;

    private DNTApi() {
        RestAdapter adapter = new RestAdapter.Builder()
                .setEndpoint("https://www.dnt.no/")
                .setLogLevel(RestAdapter.LogLevel.FULL)
                .build();

        api = adapter.create(Endpoints.class);
    }

    public static DNTApi getInstance() {
        return ourInstance;
    }

    public static Endpoints call() {
        return getInstance().api;
    }

    public interface Endpoints {

        @FormUrlEncoded
        @POST("/o/token/")
        void getToken(@Field("grant_type") String grant_type,
                      @Field("code") String code,
                      @Field("redirect_uri") String redirect_uri,
                      @Field("client_id") String client_id,
                      @Field("client_secret") String client_secret,
                      Callback<AuthorizationToken> callback);

        @FormUrlEncoded
        @POST("/o/token/")
        void refreshToken(@Field("grant_type") String grant_type,
                          @Field("refresh_token") String refresh_token,
                          @Field("redirect_uri") String redirect_uri,
                          @Field("client_id") String client_id,
                          @Field("client_secret") String client_secret,
                          Callback<AuthorizationToken> callback);

        @GET("/api/oauth/medlemsdata/")
        void getMember(@Header("Authorization") String authorization, Callback<MemberData> callback);
    }
}
