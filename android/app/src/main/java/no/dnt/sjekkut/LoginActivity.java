package no.dnt.sjekkut;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginActivity extends ActionBarActivity {

    private String client_id;
    private String client_secret;
    private Callback<AuthorizationToken> mAuthorizeCallback;
    private boolean mGettingToken = false;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        if (PreferenceUtils.hasAccessToken(this)) {
            finishAndStartMain();
            return;
        }

        mGettingToken = false;
        client_id = getResources().getString(R.string.client_id);
        client_secret = getResources().getString(R.string.client_secret);
        String authorizationUrl = Uri.parse("https://www.dnt.no/o/authorize/")
                .buildUpon()
                .appendQueryParameter("client_id", client_id)
                .appendQueryParameter("response_type", "code")
                .build().toString();

        mAuthorizeCallback = new Callback<AuthorizationToken>() {

            @Override
            public void onResponse(Call<AuthorizationToken> call, Response<AuthorizationToken> response) {
                if (response.isSuccessful()) {
                    Utils.showToast(LoginActivity.this, "Authorization success");
                    AuthorizationToken token = response.body();
                    PreferenceUtils.setAccessAndRefreshToken(LoginActivity.this, token.access_token, token.refresh_token);
                    finishAndStartMain();
                } else {
                    Utils.showToast(LoginActivity.this, "Authorization failed: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<AuthorizationToken> call, Throwable t) {
                Utils.showToast(LoginActivity.this, "Authorization failed: " + t.getLocalizedMessage());
            }
        };

        WebView webview = new WebView(this);
        setContentView(webview);
        webview.getSettings().setJavaScriptEnabled(true);
        webview.setVisibility(View.VISIBLE);
        webview.setWebViewClient(new WebViewClient() {
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                view.loadUrl(url);
                return true;
            }

            @Override
            public void onPageFinished(final WebView webView, final String url) {
                if (url.startsWith(DNTApi.OAUTH2_REDIRECT_URL)) {
                    webView.setVisibility(View.INVISIBLE);
                    if (!mGettingToken) {
                        mGettingToken = true;
                        String code = Utils.extractUrlArgument(url, "code", null);
                        if (code != null) {
                            Call<AuthorizationToken> call = DNTApi.call().getToken("authorization_code", code, DNTApi.OAUTH2_REDIRECT_URL, client_id, client_secret);
                            call.enqueue(mAuthorizeCallback);
                        } else {
                            Utils.logout(LoginActivity.this);
                        }
                    }
                } else {
                    webView.setVisibility(View.VISIBLE);
                }
            }
        });
        Utils.clearCookies(this);
        webview.loadUrl(authorizationUrl);
    }

    private void finishAndStartMain() {
        startActivity(new Intent(this, MainActivity.class));
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        finish();
    }
}