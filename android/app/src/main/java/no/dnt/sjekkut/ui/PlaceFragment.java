package no.dnt.sjekkut.ui;

import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;
import com.squareup.picasso.Picasso;

import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.UserCheckins;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;


/**
 * Copyright Den Norske Turistforening 2015
 * <p/>
 * Created by espen on 05.02.2015.
 */
public class PlaceFragment extends Fragment implements LocationListener, View.OnClickListener {

    private final static long CHECKIN_TIMESPAN_THRESHOLD_MILLISECONDS = 24 * 60 * 60 * 1000;
    private final static float CHECKIN_DISTANCE_THRESHOLD_METERS = 200.0f;
    private final static int MAP_ZOOMLEVEL = 14;
    private static final String BUNDLE_PLACE_ID = "bundle_place_id";

    private final LocationRequest mLocationRequest;
    private Location mLocation;
    private Callback<Place> mPlaceCallback;
    private Callback<UserCheckins> mUserCheckinsCallback;
    private int mCallbackRefCount = 0;
    private String mCallbackDescription = "";
    private String mPlaceId = null;
    private Place mPlace = null;
    private UserCheckins mUserCheckins = null;

    public PlaceFragment() {
        mLocationRequest = LocationRequestUtils.singleShotRequest();

        mPlaceCallback = new Callback<Place>() {
            @Override
            public void onResponse(Call<Place> call, Response<Place> response) {
                --mCallbackRefCount;
                if (response.isSuccessful()) {
                    setPlace(response.body());
                } else {
                    Utils.showToast(getActivity(), getString(R.string.checkin_no_mountain));
                    updateView();
                }
            }

            @Override
            public void onFailure(Call<Place> call, Throwable t) {
                --mCallbackRefCount;
                Utils.showToast(getActivity(), getString(R.string.checkin_no_mountain));
                updateView();
            }
        };

        mUserCheckinsCallback = new Callback<UserCheckins>() {
            @Override
            public void onResponse(Call<UserCheckins> call, Response<UserCheckins> response) {
                --mCallbackRefCount;
                if (response.isSuccessful()) {
                    mUserCheckins = response.body();
                } else {
                    Utils.showToast(getActivity(), getString(R.string.checkin_no_checkins));
                }
                updateView();
            }

            @Override
            public void onFailure(Call<UserCheckins> call, Throwable t) {
                --mCallbackRefCount;
                Utils.showToast(getActivity(), getString(R.string.checkin_no_checkins));
                updateView();
            }
        };
    }

    public static PlaceFragment newInstance(String placeId) {
        PlaceFragment fragment = new PlaceFragment();
        Bundle args = new Bundle();
        args.putSerializable(BUNDLE_PLACE_ID, placeId);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View fragmentView = inflater.inflate(R.layout.fragment_place, container, false);
        Toolbar toolbar = (Toolbar) fragmentView.findViewById(R.id.toolbar);
        if (toolbar != null && getActivity() instanceof AppCompatActivity) {
            ((AppCompatActivity) getActivity()).setSupportActionBar(toolbar);
        }
        return fragmentView;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        mPlaceId = getArguments().getString(BUNDLE_PLACE_ID, "");
        Utils.toggleUpButton(getActivity(), true);
        if (getView() != null) {
            Button checkinButton = (Button) getView().findViewById(R.id.checkin);
            if (checkinButton != null) {
                checkinButton.setOnClickListener(this);
            }
        }

        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).startLocationUpdates(this, mLocationRequest);
            ++mCallbackRefCount;
            mCallbackDescription = getString(R.string.callback_finding_posisjon);
            updateView();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        TripApiSingleton.call().getPlace(
                mPlaceId,
                getString(R.string.api_key),
                "bilder")
                .enqueue(mPlaceCallback);
        ++mCallbackRefCount;
        CheckinApiSingleton.call().getUserCheckins(
                PreferenceUtils.getUserId(getActivity()))
                .enqueue(mUserCheckinsCallback);
        ++mCallbackRefCount;
        mCallbackDescription = getString(R.string.callback_checkins_and_statistics);
        updateView();
    }

    @Override
    public void onLocationChanged(Location location) {
        --mCallbackRefCount;
        mLocation = location;
        if (isAdded()) {
            if (mLocation == null) {
                Utils.showToast(getActivity(), getString(R.string.error_did_not_find_position));
                updateView();
            } else {
                updateView();
            }
        }
        if (getActivity() instanceof MainActivity && getView() != null) {
            ((MainActivity) getActivity()).stopLocationUpdates(this);
        }
    }

    private void updateView() {
        if (getView() == null)
            return;

        boolean timespanOK = 0 > CHECKIN_TIMESPAN_THRESHOLD_MILLISECONDS; // TODO: calculate proper timespan since last checkin
        boolean distanceOK = mPlace != null && mPlace.hasLocation() && mLocation != null && mLocation.distanceTo(mPlace.getLocation()) < CHECKIN_DISTANCE_THRESHOLD_METERS;
        boolean viewButtonChecksIn = timespanOK && distanceOK;
        boolean callbacksInProgress = mCallbackRefCount > 0;
        int progressVisibility = callbacksInProgress ? View.VISIBLE : View.INVISIBLE;
        int viewVisibility = callbacksInProgress ? View.INVISIBLE : View.VISIBLE;

        // Progress bar

        ProgressBar progress = (ProgressBar) getView().findViewById(R.id.progress);
        if (progress != null) {
            progress.setVisibility(progressVisibility);
        }

        TextView text = (TextView) getView().findViewById(R.id.progress_text);
        if (text != null) {
            text.setVisibility(progressVisibility);
            if (mCallbackDescription != null) {
                text.setText(mCallbackDescription);
            }
        }

        // Views

        View topContainer = getView().findViewById(R.id.topContainer);
        if (topContainer != null) {
            topContainer.setVisibility(viewVisibility);
        }

        TextView name = (TextView) getView().findViewById(R.id.name);
        if (name != null) {
            String mountainName = mPlace != null ? mPlace.navn : getString(R.string.unknown_mountain_name);
            name.setText(mountainName);
        }
        TextView countyAndHeight = (TextView) getView().findViewById(R.id.county_and_height);
        if (countyAndHeight != null) {
            String county = mPlace != null ? mPlace.fylke : getString(R.string.unknown_mountain_county);
            double height = 0.0d; // TODO: add or remove height info
            countyAndHeight.setText(getString(R.string.county_and_height, county, height));
        }
        TextView summits = (TextView) getView().findViewById(R.id.summits);
        if (summits != null && mUserCheckins != null) {
            int count = mUserCheckins.getNumberOfVisits(mPlaceId);
            summits.setText(getString(R.string.summits, count));
        }
        TextView distance = (TextView) getView().findViewById(R.id.distance);
        if (distance != null) {
            String distanceText = mPlace != null && mPlace.hasLocation() && mLocation != null ?
                    Utils.formatDistance(getActivity(), mLocation.distanceTo(mPlace.getLocation())) : "n/a";
            distance.setText(getString(R.string.distance_to_you, distanceText));
        }
        ImageView image = (ImageView) getView().findViewById(R.id.image);
        if (image != null) {
            if (mPlace != null) {
                Picasso.with(getActivity()).load(mPlace.getImageUrl((int) (Utils.getDisplayWidth(getActivity()) * .25f))).fit().centerCrop().into(image);
            } else {
                image.setImageResource(0);
            }
        }
        ImageView map = (ImageView) getView().findViewById(R.id.map);
        if (map != null) {
            if (mPlace != null && mPlace.hasLocation()) {
                Picasso.with(getActivity()).load(Utils.getMapUrl(
                        Utils.getDisplayWidth(getActivity()),
                        getResources().getDimensionPixelSize(R.dimen.map_height),
                        mPlace.getLocation(),
                        mLocation,
                        MAP_ZOOMLEVEL)).into(map);
            } else {
                map.setImageResource(0);
            }
        }
        TextView scaleBar = (TextView) getView().findViewById(R.id.scale);
        if (scaleBar != null) {
            double mapMeters = getResources().getDimensionPixelSize(R.dimen.scalebar_width) * Utils.getMetersPerPixelForGoogleStaticMaps(mLocation, MAP_ZOOMLEVEL);
            scaleBar.setText(Utils.formatDistance(getActivity(), mapMeters));
        }

        Button checkinButton = (Button) getView().findViewById(R.id.checkin);
        if (checkinButton != null) {
            if (viewButtonChecksIn) {
                checkinButton.setText(getString(R.string.checkin_button));
                Utils.setColorFilter(checkinButton, getResources().getColor(R.color.dntRed));
                checkinButton.setTextColor(getResources().getColor(R.color.white));
            } else {
                checkinButton.setText(getString(R.string.checkin_back));
                Utils.setColorFilter(checkinButton, getResources().getColor(R.color.dntLightGray));
                checkinButton.setTextColor(getResources().getColor(R.color.black));
            }
        }
        TextView checkinButtonText = (TextView) getView().findViewById(R.id.checkin_button_text);
        if (checkinButtonText != null) {
            if (viewButtonChecksIn) {
                checkinButtonText.setText(getString(R.string.checkin_available));
            } else {
                if (!distanceOK && !timespanOK) {
                    checkinButtonText.setText(getString(R.string.checkin_not_available_because_distance_and_timespan));
                } else if (!distanceOK) {
                    checkinButtonText.setText(getString(R.string.checkin_not_available_because_distance));
                } else {
                    checkinButtonText.setText(getString(R.string.checkin_not_available_because_timespan));
                }
            }
        }
        TextView descriptionSeparator = (TextView) getView().findViewById(R.id.description_separator);
        if (descriptionSeparator != null) {
            descriptionSeparator.setText(getString(R.string.description_separator));
        }
        TextView descriptionText = (TextView) getView().findViewById(R.id.description);
        if (descriptionText != null) {
            String mountainDescription = mPlace != null ? mPlace.beskrivelse : getString(R.string.unknown_mountain_description);
            descriptionText.setText(mountainDescription);
        }
        TextView checkinSeparator = (TextView) getView().findViewById(R.id.checkin_separator_title);
        if (checkinSeparator != null) {
            checkinSeparator.setText(getString(R.string.checkin_separator_title));
        }
        TextView checkinText = (TextView) getView().findViewById(R.id.checkin_text);
        if (checkinText != null) {
            String checkinDescription = getCheckinStatsString();
            checkinText.setText(checkinDescription);
        }
    }

    private void setPlace(Place place) {
        mPlace = place;
        Utils.setActionBarTitle(getActivity(), mPlace != null && mPlace.navn != null ? mPlace.navn : "");
        updateView();
    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.checkin:
                // TODO: actually implement some checkin stuff
                Utils.showToast(getActivity(), "Not implemented");
        }
    }

    private String getCheckinStatsString() {
        return getString(R.string.checkin_data_missing);
    }
}
