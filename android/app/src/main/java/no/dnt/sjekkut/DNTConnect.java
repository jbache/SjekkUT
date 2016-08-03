package no.dnt.sjekkut;

import retrofit.Callback;
import retrofit.RestAdapter;
import retrofit.http.Field;
import retrofit.http.FormUrlEncoded;
import retrofit.http.POST;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */
public class DNTConnect {
    private static DNTConnect ourInstance = new DNTConnect();

    public final Endpoints api;

    private DNTConnect() {
        RestAdapter adapter = new RestAdapter.Builder()
                .setEndpoint("https://www.dnt.no/")
                .setLogLevel(RestAdapter.LogLevel.FULL)
                .build();

        api = adapter.create(Endpoints.class);
    }

    public static DNTConnect getInstance() {
        return ourInstance;
    }

    public interface Endpoints {

        @FormUrlEncoded
        @POST("/o/token/")
        void getToken(@Field("grant_type") String grant_type,
                      @Field("code") String code,
                      @Field("redirect_uri") String redirect_uri,
                      @Field("client_id") String client_id,
                      @Field("client_secret") String client_secret,
                      Callback<DNTConnectToken> cb);

        @FormUrlEncoded
        @POST("/o/token/")
        void refreshToken(@Field("grant_type") String grant_type,
                          @Field("refresh_token") String refresh_token,
                          @Field("redirect_uri") String redirect_uri,
                          @Field("client_id") String client_id,
                          @Field("client_secret") String client_secret,
                          Callback<DNTConnectToken> cb);
    }
}
