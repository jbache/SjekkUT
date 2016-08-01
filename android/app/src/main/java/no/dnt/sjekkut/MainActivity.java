package no.dnt.sjekkut;

import android.app.Activity;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentSender;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.DialogFragment;
import android.support.v7.app.ActionBarActivity;
import android.util.Pair;
import android.view.MenuItem;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;

import net.hockeyapp.android.CrashManager;
import net.hockeyapp.android.FeedbackManager;
import net.hockeyapp.android.UpdateManager;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Date;

public class MainActivity extends ActionBarActivity implements GoogleApiClient.ConnectionCallbacks, GoogleApiClient.OnConnectionFailedListener {

    private GoogleApiClient mGoogleApiClient;
    private static final int REQUEST_RESOLVE_ERROR = 1001;
    private static final long MAX_LOCATION_TIME_DELTA_MS = 60*1000;
    private static final String DIALOG_ERROR = "dialog_error";
    private boolean mResolvingError = false;
    private ArrayList<Pair<LocationListener, LocationRequest>> mPendingListener = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        OppturApi.sActivityReference = new WeakReference<Activity>(this);

        mGoogleApiClient = new GoogleApiClient.Builder(this)
                .addConnectionCallbacks(this)
                .addOnConnectionFailedListener(this)
                .addApi(LocationServices.API)
                .build();

        setContentView(R.layout.activity_main);
        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction()
                    .add(R.id.container, new SummitListFragment())
                    .commit();
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                getSupportFragmentManager().popBackStack();
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (!mResolvingError && !mGoogleApiClient.isConnecting() && !mGoogleApiClient.isConnected()) {
            mGoogleApiClient.connect();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        checkForCrashes();
        checkForUpdates();
    }

    @Override
    protected void onStop() {
        mPendingListener.clear();
        if (mGoogleApiClient.isConnected()) {
            mGoogleApiClient.disconnect();
        }
        super.onStop();
    }

    @Override
    public void onConnected(Bundle bundle) {
        for (Pair<LocationListener, LocationRequest> pending : mPendingListener) {
            startLocationUpdates(pending.first, pending.second);
        }
        mPendingListener.clear();
    }

    @Override
    public void onConnectionSuspended(int i) {
        if (!mGoogleApiClient.isConnecting() && !mGoogleApiClient.isConnected()) {
            mGoogleApiClient.connect();
        }
    }

    @Override
    public void onConnectionFailed(ConnectionResult result) {
        if (mResolvingError) {
            return;
        }

        if (result.hasResolution()) {
            try {
                mResolvingError = true;
                result.startResolutionForResult(this, REQUEST_RESOLVE_ERROR);
            } catch (IntentSender.SendIntentException e) {
                mGoogleApiClient.connect();
            }
        } else {
            showErrorDialog(result.getErrorCode());
            mResolvingError = true;
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == REQUEST_RESOLVE_ERROR) {
            mResolvingError = false;
            if (resultCode == RESULT_OK) {
                if (!mGoogleApiClient.isConnecting() && !mGoogleApiClient.isConnected()) {
                    mGoogleApiClient.connect();
                }
            }
        }
    }

    private void showErrorDialog(int errorCode) {
        ErrorDialogFragment dialogFragment = new ErrorDialogFragment();
        Bundle args = new Bundle();
        args.putInt(DIALOG_ERROR, errorCode);
        dialogFragment.setArguments(args);
        dialogFragment.show(getSupportFragmentManager(), "errordialog");
    }

    public void onDialogDismissed() {
        mResolvingError = false;
    }

    public static class ErrorDialogFragment extends DialogFragment {
        public ErrorDialogFragment() {
        }

        @NonNull
        @Override
        public Dialog onCreateDialog(Bundle savedInstanceState) {
            int errorCode = this.getArguments().getInt(DIALOG_ERROR);
            return GooglePlayServicesUtil.getErrorDialog(errorCode,
                    this.getActivity(), REQUEST_RESOLVE_ERROR);
        }

        @Override
        public void onDismiss(DialogInterface dialog) {
            ((MainActivity) getActivity()).onDialogDismissed();
        }
    }

    public void startLocationUpdates(LocationListener listener, LocationRequest locationRequest) {
        if (mGoogleApiClient.isConnected()) {
            Location lastLocation = LocationServices.FusedLocationApi.getLastLocation(mGoogleApiClient);
            long locationDelta = lastLocation != null ? new Date().getTime() - lastLocation.getTime() : Long.MAX_VALUE;
            if (locationDelta < MAX_LOCATION_TIME_DELTA_MS) {
                listener.onLocationChanged(lastLocation);
            } else {
                LocationServices.FusedLocationApi.requestLocationUpdates(mGoogleApiClient, locationRequest, listener);
            }
        } else {
            mPendingListener.add(Pair.create(listener, locationRequest));
        }
        if (!Utils.isAccurateGPSEnabled(this)) {
            Utils.showToast(this, getString(R.string.gps_warning));
        }
    }

    public void stopLocationUpdates(LocationListener listener) {
        if (mGoogleApiClient.isConnected()) {
            LocationServices.FusedLocationApi.removeLocationUpdates(mGoogleApiClient, listener);
        }
    }

    private void checkForCrashes() {
        CrashManager.register(this, "a87641b00a6012bad617ba8f0a217b32");
    }

    private void checkForUpdates() {
        // TODO: Remove this for store builds!
        UpdateManager.register(this, "a87641b00a6012bad617ba8f0a217b32");
    }

    public static void showFeedbackActivity(Activity activity) {
        if (activity == null)
            return;

        FeedbackManager.register(activity, "a87641b00a6012bad617ba8f0a217b32", null);
        FeedbackManager.showFeedbackActivity(activity);
    }
}
