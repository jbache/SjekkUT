package no.dnt.sjekkut;

import android.net.Uri;
import android.os.Bundle;
import android.support.v7.app.ActionBarActivity;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import retrofit.Callback;
import retrofit.RetrofitError;
import retrofit.client.Response;

public class LoginActivity extends ActionBarActivity {

    private String redirectURL = "https://localhost/callback";
    private String client_id;
    private String client_secret;
    private Callback<AuthorizationToken> authorizeCallback;
    private Callback<AuthorizationToken> refreshCallback;
    private Callback<MemberData> memberCallback;

    private boolean gettingToken = false;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        gettingToken = false;
        client_id = getResources().getString(R.string.client_id);
        client_secret = getResources().getString(R.string.client_secret);
        String authorizationUrl = Uri.parse("https://www.dnt.no/o/authorize/")
                .buildUpon()
                .appendQueryParameter("client_id", client_id)
                .appendQueryParameter("response_type", "code")
                .build().toString();

        authorizeCallback = new Callback<AuthorizationToken>() {

            @Override
            public void success(AuthorizationToken authorizationToken, Response response) {
                Utils.showToast(LoginActivity.this, "Authorization success");
                DNTApi.call().refreshToken("refresh_token", authorizationToken.refresh_token, redirectURL, client_id, client_secret, refreshCallback);
                DNTApi.call().getMember(authorizationToken.token_type + " " + authorizationToken.access_token, memberCallback);
            }

            @Override
            public void failure(RetrofitError error) {
                Utils.showToast(LoginActivity.this, "Authorization failed");
            }
        };

        refreshCallback = new Callback<AuthorizationToken>() {

            @Override
            public void success(AuthorizationToken authorizationToken, Response response) {
                Utils.showToast(LoginActivity.this, "Refresh token success");
            }

            @Override
            public void failure(RetrofitError error) {
                Utils.showToast(LoginActivity.this, "Refresh token failed");
            }
        };

        memberCallback = new Callback<MemberData>() {
            @Override
            public void success(MemberData memberData, Response response) {
                Utils.showToast(LoginActivity.this, "getMember success");
            }

            @Override
            public void failure(RetrofitError error) {
                Utils.showToast(LoginActivity.this, "getMember failed");
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
                if (url.startsWith(redirectURL)) {
                    webView.setVisibility(View.INVISIBLE);
                    if (!gettingToken) {
                        gettingToken = true;
                        String code = Utils.extractUrlArgument(url, "code", "");
                        DNTApi.call().getToken("authorization_code", code, redirectURL, client_id, client_secret, authorizeCallback);
                    }
                } else {
                    webView.setVisibility(View.VISIBLE);
                }
            }
        });
        Utils.clearCookies(this);
        webview.loadUrl(authorizationUrl);
    }


}