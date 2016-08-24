package no.dnt.sjekkut.ui;

import android.app.Activity;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentSender;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.DialogFragment;
import android.support.v7.app.AppCompatActivity;
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

import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.dummy.DummyContent;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.CheckinLocation;
import no.dnt.sjekkut.network.CheckinResult;
import no.dnt.sjekkut.network.LoginApiSingleton;
import no.dnt.sjekkut.network.MemberData;
import no.dnt.sjekkut.network.OppturApi;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.PlaceCheckinList;
import no.dnt.sjekkut.network.PlaceCheckinStats;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.ProjectList;
import no.dnt.sjekkut.network.TripApiSingleton;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class MainActivity extends AppCompatActivity implements GoogleApiClient.ConnectionCallbacks, GoogleApiClient.OnConnectionFailedListener, ProjectListFragment.ProjectListListener, ProfileStatsFragment.ProfileStatsListener {

    private static final int REQUEST_RESOLVE_ERROR = 1001;
    private static final long MAX_LOCATION_TIME_DELTA_MS = 60 * 1000;
    private static final String DIALOG_ERROR = "dialog_error";
    private GoogleApiClient mGoogleApiClient;
    private boolean mResolvingError = false;
    private ArrayList<Pair<LocationListener, LocationRequest>> mPendingListener = new ArrayList<>();
    private Callback<MemberData> mMemberCallback;
    private Callback<ProjectList> mProjectListCallback;
    private Callback<Project> mProjectCallback;
    private Callback<Place> mPlaceCallback;
    private Callback<PlaceCheckinList> mPlaceCheckinList;
    private Callback<PlaceCheckinStats> mPlaceCheckinStats;
    private Callback<CheckinResult> mPostCheckin;

    public static void showFeedbackActivity(Activity activity) {
        if (activity == null)
            return;

        FeedbackManager.register(activity);
        FeedbackManager.showFeedbackActivity(activity);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        OppturApi.sActivityReference = new WeakReference<Activity>(this);

        mGoogleApiClient = new GoogleApiClient.Builder(this)
                .addConnectionCallbacks(this)
                .addOnConnectionFailedListener(this)
                .addApi(LocationServices.API)
                .build();

        mMemberCallback = new Callback<MemberData>() {
            @Override
            public void onResponse(Call<MemberData> call, Response<MemberData> response) {
                if (response.isSuccessful()) {
                    PreferenceUtils.setUserId(MainActivity.this, response.body().sherpa_id);
                    Utils.showToast(MainActivity.this, "Got member data");
                } else {
                    Utils.showToast(MainActivity.this, "Failed to get member data: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<MemberData> call, Throwable t) {
                Utils.showToast(MainActivity.this, "Failed to get member data: " + t.getLocalizedMessage());
            }
        };

        mProjectListCallback = new Callback<ProjectList>() {
            @Override
            public void onResponse(Call<ProjectList> call, Response<ProjectList> response) {
                if (response.isSuccessful()) {
                    Utils.showToast(MainActivity.this, "Got " + response.body().total + " projects");
                    int lastProjectIndex = response.body().documents.size() - 1;
                    Project lastProject = response.body().documents.get(lastProjectIndex);
                    TripApiSingleton.call().getProject(
                            lastProject._id,
                            getString(R.string.api_key),
                            "steder,geojson,bilder,img,kommune,beskrivelse",
                            "steder,bilder"
                    ).enqueue(mProjectCallback);
                } else {
                    Utils.showToast(MainActivity.this, "Failed to get project list: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<ProjectList> call, Throwable t) {
                Utils.showToast(MainActivity.this, "Failed to get project list: " + t.getLocalizedMessage());
            }
        };

        mProjectCallback = new Callback<Project>() {
            @Override
            public void onResponse(Call<Project> call, Response<Project> response) {
                if (response.isSuccessful()) {
                    Utils.showToast(MainActivity.this, "Got project " + response.body().navn);
                    int lastPlaceIndex = response.body().steder.size();
                    Place lastPlace = response.body().steder.get(lastPlaceIndex - 1);
                    TripApiSingleton.call().getPlace(
                            lastPlace._id,
                            getString(R.string.api_key),
                            "bilder"
                    ).enqueue(mPlaceCallback);
                } else {
                    Utils.showToast(MainActivity.this, "Failed to get project: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<Project> call, Throwable t) {
                Utils.showToast(MainActivity.this, "Failed to get project: " + t.getLocalizedMessage());

            }
        };

        mPlaceCallback = new Callback<Place>() {
            @Override
            public void onResponse(Call<Place> call, Response<Place> response) {
                if (response.isSuccessful()) {
                    Place place = response.body();
                    Utils.showToast(MainActivity.this, "Got place: " + place.navn);
                    CheckinApiSingleton.call().getPlaceCheckinList(place._id).enqueue(mPlaceCheckinList);
                    CheckinApiSingleton.call().getPlaceCheckinStats(place._id).enqueue(mPlaceCheckinStats);
                    CheckinApiSingleton.call().postPlaceCheckin(
                            PreferenceUtils.getUserId(MainActivity.this),
                            PreferenceUtils.getAccessToken(MainActivity.this),
                            place._id,
                            new CheckinLocation()
                    ).enqueue(mPostCheckin);
                } else {
                    Utils.showToast(MainActivity.this, "Failed to get place: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<Place> call, Throwable t) {
                Utils.showToast(MainActivity.this, "Failed to get place: " + t.getLocalizedMessage());
            }
        };

        mPlaceCheckinList = new Callback<PlaceCheckinList>() {
            @Override
            public void onResponse(Call<PlaceCheckinList> call, Response<PlaceCheckinList> response) {
                if (response.isSuccessful()) {
                    Utils.showToast(MainActivity.this, "Got place checkin list: " + response.body().data.size());
                } else {
                    Utils.showToast(MainActivity.this, "Failed to get place checkin list: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<PlaceCheckinList> call, Throwable t) {
                Utils.showToast(MainActivity.this, "Failed to get place checkin list: " + t.getLocalizedMessage());
            }
        };

        mPlaceCheckinStats = new Callback<PlaceCheckinStats>() {
            @Override
            public void onResponse(Call<PlaceCheckinStats> call, Response<PlaceCheckinStats> response) {
                if (response.isSuccessful()) {
                    Utils.showToast(MainActivity.this, "Got place checkin stats count: " + response.body().data.count);
                } else {
                    Utils.showToast(MainActivity.this, "Failed to get place checkin stats: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<PlaceCheckinStats> call, Throwable t) {
                Utils.showToast(MainActivity.this, "Failed to get place checkin stats: " + t.getLocalizedMessage());
            }
        };

        mPostCheckin = new Callback<CheckinResult>() {
            @Override
            public void onResponse(Call<CheckinResult> call, Response<CheckinResult> response) {
                if (response.isSuccessful()) {
                    Utils.showToast(MainActivity.this, "Checkin at: " + response.body().message);
                } else {
                    Utils.showToast(MainActivity.this, "Failed to checkin: " + response.body());
                }
            }

            @Override
            public void onFailure(Call<CheckinResult> call, Throwable t) {
                Utils.showToast(MainActivity.this, "Failed to checkin: " + t.getLocalizedMessage());
            }
        };

        setContentView(R.layout.activity_main);
        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction()
                    .add(R.id.container, new ProjectListFragment())
                    .commit();
        }
        checkForUpdates();
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
        LoginApiSingleton.call().getMember(PreferenceUtils.getBearerAuthorization(this)).enqueue(mMemberCallback);
        TripApiSingleton.call().getProjectList(getString(R.string.api_key), "steder,bilder,geojson,grupper").enqueue(mProjectListCallback);
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
    protected void onPause() {
        super.onPause();
        unregisterManagers();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterManagers();
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
        CrashManager.register(this);
    }

    private void checkForUpdates() {
        // TODO: Remove this for store builds!
        UpdateManager.register(this);
    }

    private void unregisterManagers() {
        UpdateManager.unregister();
    }

    @Override
    public void onProjectClicked(Project project) {
        Utils.showToast(MainActivity.this, "Clicked on project: " + project.navn);
        getSupportFragmentManager().beginTransaction()
                .replace(R.id.container, new SummitListFragment())
                .addToBackStack(SummitListFragment.class.getCanonicalName())
                .commit();
    }

    @Override
    public void onProfileClicked() {
        getSupportFragmentManager().beginTransaction()
                .replace(R.id.container, new ProfileStatsFragment())
                .addToBackStack(ProfileStatsFragment.class.getCanonicalName())
                .commit();
    }

    @Override
    public void onListFragmentInteraction(DummyContent.DummyItem item) {
        Utils.showToast(MainActivity.this, "Todo");
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
}
