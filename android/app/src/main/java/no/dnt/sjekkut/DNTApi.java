package no.dnt.sjekkut;

import android.content.Context;

import java.io.IOException;
import java.net.HttpURLConnection;

import okhttp3.Authenticator;
import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.Route;
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

    public static final String OAUTH2_REDIRECT_URL = "https://localhost/callback";
    private static DNTApi ourInstance = new DNTApi();

    private final Endpoints api;

    private DNTApi() {

        final Context appContext = SjekkUTApplication.getContext();
        final String refreshToken = PreferenceUtils.getRefreshToken(appContext);
        final String client_id = appContext.getResources().getString(R.string.client_id);
        final String client_secret = appContext.getResources().getString(R.string.client_secret);

        Authenticator refreshAuthenticator = new Authenticator() {
            @Override
            public Request authenticate(Route route, Response response) throws IOException {
                if (PreferenceUtils.hasRefreshToken(appContext)) {
                    retrofit2.Response<AuthorizationToken> refresh = call().refreshToken("refresh_token", refreshToken, OAUTH2_REDIRECT_URL, client_id, client_secret).execute();
                    if (refresh.isSuccessful()) {
                        PreferenceUtils.setAccessAndRefreshToken(
                                appContext,
                                refresh.body().access_token,
                                refresh.body().refresh_token
                        );
                        return response.request().newBuilder()
                                .header("Authorization", PreferenceUtils.getBearerAuthorization(appContext))
                                .build();
                    }
                }
                return null;
            }
        };

        Interceptor rewrite403to401Interceptor = new Interceptor() {
            @Override
            public Response intercept(Interceptor.Chain chain) throws IOException {
                Response originalResponse = chain.proceed(chain.request());
                if (!originalResponse.isRedirect() &&
                        originalResponse.request().url().encodedPath().contains("api/oauth/medlemsdata/") &&
                        originalResponse.code() == HttpURLConnection.HTTP_FORBIDDEN) {
                    return originalResponse.newBuilder().code(HttpURLConnection.HTTP_UNAUTHORIZED).build();
                } else {
                    return originalResponse;
                }
            }
        };

        HttpLoggingInterceptor loggingInterceptor = new HttpLoggingInterceptor();
        if (BuildConfig.DEBUG) {
            loggingInterceptor.setLevel(HttpLoggingInterceptor.Level.BODY);
        } else {
            loggingInterceptor.setLevel(HttpLoggingInterceptor.Level.NONE);
        }

        OkHttpClient httpClient = new OkHttpClient.Builder()
                .addNetworkInterceptor(rewrite403to401Interceptor)
                .authenticator(refreshAuthenticator)
                .addInterceptor(loggingInterceptor)
                .build();

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
