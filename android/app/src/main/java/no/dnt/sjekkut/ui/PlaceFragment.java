package no.dnt.sjekkut.ui;

import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.widget.Toolbar;
import android.text.Html;
import android.text.SpannableString;
import android.text.method.LinkMovementMethod;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
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
public class PlaceFragment extends Fragment implements LocationListener {

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
                    Utils.showToast(getActivity(), getString(R.string.checkin_no_place));
                    updateView();
                }
            }

            @Override
            public void onFailure(Call<Place> call, Throwable t) {
                --mCallbackRefCount;
                Utils.showToast(getActivity(), getString(R.string.checkin_no_place));
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

    static PlaceFragment newInstance(String placeId) {
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
        Utils.setupSupportToolbar(getActivity(), toolbar, getString(R.string.screen_place), true);
        setHasOptionsMenu(true);
        return fragmentView;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        mPlaceId = getArguments().getString(BUNDLE_PLACE_ID, "");
        Utils.toggleUpButton(getActivity(), true);
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
                TripApiSingleton.PLACE_EXPAND)
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
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_feedback, menu);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.feedback:
                MainActivity.showFeedbackActivity(getActivity());
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
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
            String placeName = mPlace != null ? mPlace.navn : getString(R.string.unknown_place);
            name.setText(placeName);
        }
        TextView countyAndHeight = (TextView) getView().findViewById(R.id.county);
        if (countyAndHeight != null) {
            String county = mPlace != null ? mPlace.fylke : getString(R.string.unknown_county);
            countyAndHeight.setText(getString(R.string.county, county));
        }
        TextView visits = (TextView) getView().findViewById(R.id.visits);
        if (visits != null && mUserCheckins != null) {
            int count = mUserCheckins.getNumberOfVisits(mPlaceId);
            visits.setText(getString(R.string.visits, count));
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

        TextView descriptionSeparator = (TextView) getView().findViewById(R.id.description_separator);
        if (descriptionSeparator != null) {
            descriptionSeparator.setText(getString(R.string.description_separator));
        }
        TextView descriptionText = (TextView) getView().findViewById(R.id.description);
        if (descriptionText != null) {
            String placeDescription = mPlace != null && mPlace.beskrivelse != null ? mPlace.beskrivelse : getString(R.string.unknown_place_description);
            SpannableString formattedDescription = new SpannableString(Html.fromHtml(placeDescription));
            descriptionText.setText(formattedDescription, TextView.BufferType.SPANNABLE);
        }
        TextView homepageSeparator = (TextView) getView().findViewById(R.id.homepage_separator_title);
        if (homepageSeparator != null) {
            homepageSeparator.setText(getString(R.string.homepage_separator));
        }
        TextView homepageText = (TextView) getView().findViewById(R.id.homepage_text);
        if (homepageText != null) {
            homepageText.setMovementMethod(LinkMovementMethod.getInstance());
            homepageText.setText(Html.fromHtml(getString(R.string.more_on_homepage)));
            String homepageUrl = mPlace != null ? mPlace.getHomePageUrl() : null;
            String homepageLinkedText = getString(R.string.no_homepage);
            if (homepageUrl != null) {
                homepageLinkedText = getString(R.string.more_on_homepage, homepageUrl);
            }
            homepageText.setText(Html.fromHtml(homepageLinkedText));
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
        updateView();
    }

    private String getCheckinStatsString() {
        return getString(R.string.checkin_data_missing);
    }
}
