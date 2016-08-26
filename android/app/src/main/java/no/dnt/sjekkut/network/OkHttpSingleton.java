package no.dnt.sjekkut.network;

import android.content.Context;

import com.facebook.stetho.okhttp3.StethoInterceptor;

import java.io.File;
import java.io.IOException;
import java.net.HttpURLConnection;

import no.dnt.sjekkut.BuildConfig;
import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.SjekkUTApplication;
import no.dnt.sjekkut.Utils;
import okhttp3.Authenticator;
import okhttp3.Cache;
import okhttp3.FormBody;
import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.Route;
import okhttp3.logging.HttpLoggingInterceptor;
import timber.log.Timber;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 09.08.2016.
 */
public enum OkHttpSingleton {
    INSTANCE;

    private static final String CACHE_DIR_NAME = "okhttp3_cache";
    private static final long CACHE_SIZE_BYTES = 1024 * 1024 * 20; // 20MB;
    private final OkHttpClient mHttpClient = createClient();

    public static OkHttpClient getClient() {
        return INSTANCE.mHttpClient;
    }

    private OkHttpClient createClient() {
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
                    retrofit2.Response<AuthorizationToken> refresh = LoginApiSingleton.call().refreshToken(
                            "refresh_token",
                            PreferenceUtils.getRefreshToken(mAppContext),
                            LoginApiSingleton.OAUTH2_REDIRECT_URL,
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
                if (response.request().url().encodedPath().contains(LoginApiSingleton.API_TOKEN)) {
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
                        originalResponse.request().url().encodedPath().contains(LoginApiSingleton.API_MEDLEMSDATA) &&
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

        File cacheDirectory = new File(mAppContext.getCacheDir().getAbsolutePath(), CACHE_DIR_NAME);

        OkHttpClient.Builder builder = new OkHttpClient.Builder()
                .cache(new Cache(cacheDirectory, CACHE_SIZE_BYTES))
                .addNetworkInterceptor(rewrite403to401Interceptor)
                .authenticator(refreshAuthenticator)
                .addInterceptor(loggingInterceptor);
        if (BuildConfig.DEBUG) {
            builder.addNetworkInterceptor(new StethoInterceptor());
        }
        return builder.build();
    }
}
