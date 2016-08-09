package no.dnt.sjekkut;

import android.content.Context;

import java.io.IOException;
import java.net.HttpURLConnection;

import okhttp3.Authenticator;
import okhttp3.FormBody;
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
import timber.log.Timber;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */
public class DNTApi {

    public static final String OAUTH2_REDIRECT_URL = "https://localhost/callback";
    public static final String API_MEDLEMSDATA = "api/oauth/medlemsdata/";
    public static final String API_TOKEN = "o/token/";

    private static DNTApi ourInstance = new DNTApi();

    private final Endpoints api;

    private DNTApi() {

        final Context mAppContext = SjekkUTApplication.getContext();
        final String mClient_ID = mAppContext.getResources().getString(R.string.client_id);
        final String mClient_Secret = mAppContext.getResources().getString(R.string.client_secret);

        Authenticator refreshAuthenticator = new Authenticator() {
            @Override
            public Request authenticate(Route route, Response response) throws IOException {
                Timber.i("authenticate(..) url %s retry %d", response.request().url(), responseCount(response));
                if (response.priorResponse() != null) {
                    Timber.i("authenticate(..) prior url %s", response.priorResponse().request().url());
                }

                if (!PreferenceUtils.hasRefreshToken(mAppContext)) {
                    Timber.i("No refresh token");
                    Utils.logout(mAppContext);
                    return null;
                } else if (isRefreshResponse(response)) {
                    Timber.i("Authentication error using refresh_token");
                    Utils.logout(mAppContext);
                    return null;
                } else if (responseCount(response) > 3) {
                    Timber.i("Authentication retry limit");
                    Utils.logout(mAppContext);
                    return null;
                } else {
                    retrofit2.Response<AuthorizationToken> refresh = call().refreshToken(
                            "refresh_token",
                            PreferenceUtils.getRefreshToken(mAppContext),
                            OAUTH2_REDIRECT_URL,
                            mClient_ID,
                            mClient_Secret).execute();
                    if (refresh.isSuccessful()) {
                        PreferenceUtils.setAccessAndRefreshToken(
                                mAppContext,
                                refresh.body().access_token,
                                refresh.body().refresh_token);
                        Timber.i("Trying with new Authorization");
                        return response.request().newBuilder()
                                .header("Authorization", PreferenceUtils.getBearerAuthorization(mAppContext))
                                .build();
                    } else {
                        Timber.i("Giving up trying to authenticate");
                        Utils.logout(mAppContext);
                        return null;
                    }
                }
            }

            private boolean isRefreshResponse(Response response) {
                if (response.request().url().encodedPath().contains(API_TOKEN)) {
                    if (response.request().body() instanceof FormBody) {
                        FormBody body = (FormBody) response.request().body();
                        int fieldIndex = 0;
                        while (fieldIndex < body.size()) {
                            if ("refresh_token".equals(body.encodedName(fieldIndex))) {
                                return true;
                            }
                            ++fieldIndex;
                        }
                    }
                }
                return false;
            }

            private int responseCount(Response response) {
                int result = 1;
                while ((response = response.priorResponse()) != null) {
                    result++;
                }
                return result;
            }
        };

        Interceptor rewrite403to401Interceptor = new Interceptor() {
            @Override
            public Response intercept(Interceptor.Chain chain) throws IOException {
                Response originalResponse = chain.proceed(chain.request());
                if (!originalResponse.isRedirect() &&
                        originalResponse.request().url().encodedPath().contains(API_MEDLEMSDATA) &&
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
