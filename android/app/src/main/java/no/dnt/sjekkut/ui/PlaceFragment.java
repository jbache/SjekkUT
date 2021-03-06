package no.dnt.sjekkut.ui;

import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
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

import com.squareup.picasso.Picasso;

import java.util.Collections;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.PlaceCheckin;
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
public class PlaceFragment extends LocationFragment implements CheckinButton.CheckinListener {

    private final static int MAP_ZOOMLEVEL = 14;
    private static final String BUNDLE_PLACE_ID = "bundle_place_id";

    @BindView(R.id.toolbar)
    Toolbar mToolbar;
    @BindView(R.id.progress)
    ProgressBar mProgressBar;
    @BindView(R.id.progress_text)
    TextView mProgressText;
    @BindView(R.id.topContainer)
    ViewGroup mTopContainer;
    @BindView(R.id.placeContainer)
    ViewGroup mPlaceContainer;
    @BindView(R.id.map)
    ImageView mMap;
    @BindView(R.id.scale)
    TextView mScaleBar;
    @BindView(R.id.description_separator)
    TextView mDescriptionSeparator;
    @BindView(R.id.description)
    TextView mDescriptionText;
    @BindView(R.id.homepage_separator_title)
    TextView mHomepageSeparator;
    @BindView(R.id.homepage_text)
    TextView mHomepageText;
    @BindView(R.id.checkin_separator_title)
    TextView mCheckinSeparator;
    @BindView(R.id.checkin_text)
    TextView mCheckinText;
    @BindView(R.id.checkinButton)
    CheckinButton mCheckinButton;
    private Callback<Place> mPlaceCallback;
    private Callback<UserCheckins> mUserCheckinsCallback;
    private int mCallbackRefCount = 0;
    private String mCallbackDescription = "";
    private String mPlaceId = null;
    private Place mPlace = null;
    private PlaceAdapter mPlaceAdapter;
    private PlaceAdapter.PlaceViewHolder mPlaceViewHolder;
    private UserCheckins mUserCheckins = null;
    private Location mLocation;
    private PlaceCheckin mLatestCheckin = null;

    public PlaceFragment() {
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
                    mLatestCheckin = response.body().getLatestCheckin(mPlaceId);
                    mUserCheckins = response.body();
                    mPlaceAdapter.setUserCheckins(mUserCheckins);
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
        ButterKnife.bind(this, fragmentView);
        mPlaceAdapter = new PlaceAdapter(getActivity(), null);
        mPlaceViewHolder = mPlaceAdapter.onCreateViewHolder(mPlaceContainer, 0);
        mPlaceContainer.addView(mPlaceViewHolder.itemView);
        mCheckinButton.setListener(this);
        Utils.setupSupportToolbar(getActivity(), mToolbar, getString(R.string.screen_place), true);
        setHasOptionsMenu(true);
        return fragmentView;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        mPlaceId = getArguments().getString(BUNDLE_PLACE_ID, "");
        Utils.toggleUpButton(getActivity(), true);
    }

    @Override
    public void onResume() {
        super.onResume();
        fetchPlace();
        fetchUserCheckins();
        updateView();
    }

    private void fetchPlace() {
        TripApiSingleton.call().getPlace(
                mPlaceId,
                getString(R.string.api_key),
                TripApiSingleton.PLACE_EXPAND)
                .enqueue(mPlaceCallback);
        ++mCallbackRefCount;
        mCallbackDescription = getString(R.string.callback_collecting_place_data);
    }

    private void fetchUserCheckins() {
        CheckinApiSingleton.call().getUserCheckins(
                PreferenceUtils.getUserId(getContext()),
                PreferenceUtils.getAccessToken(getContext()),
                PreferenceUtils.getUserId(getContext()))
                .enqueue(mUserCheckinsCallback);
        ++mCallbackRefCount;
        mCallbackDescription = getString(R.string.callback_checkins_and_statistics);
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_share, menu);
        inflater.inflate(R.menu.menu_feedback, menu);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.feedback:
                MainActivity.showFeedbackActivity(getActivity());
                return true;
            case R.id.share:
                if (mLatestCheckin != null && mLatestCheckin.sharing_url != null && mPlace != null) {
                    Utils.sharePlaceVisit(getContext(), mPlace.navn, mLatestCheckin.sharing_url);
                } else if (mLatestCheckin != null) {
                    Utils.showToast(getActivity(), getString(R.string.server_todo_sharing_url));
                } else {
                    Utils.showToast(getActivity(), getString(R.string.sharing_checkin_requires_visit));
                }
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    @Override
    public void onLocationChanged(Location location) {
        mLocation = location;
        mCheckinButton.setLocation(location);
        mPlaceAdapter.setLocation(location);
        if (isAdded()) {
            if (location == null) {
                Utils.showToast(getActivity(), getString(R.string.error_did_not_find_position));
                updateView();
            } else {
                updateView();
            }
        }
    }

    private void updateView() {
        if (getView() == null)
            return;

        boolean callbacksInProgress = mCallbackRefCount > 0;
        int progressVisibility = callbacksInProgress ? View.VISIBLE : View.INVISIBLE;
        int viewVisibility = callbacksInProgress ? View.INVISIBLE : View.VISIBLE;

        mProgressBar.setVisibility(progressVisibility);
        mProgressText.setVisibility(progressVisibility);
        if (mCallbackDescription != null) {
            mProgressText.setText(mCallbackDescription);
        }

        mTopContainer.setVisibility(viewVisibility);
        if (mPlaceAdapter.getItemCount() > 0) {
            mPlaceAdapter.onBindViewHolder(mPlaceViewHolder, 0);
        }

        if (mPlace != null && mPlace.hasLocation()) {
            Picasso.with(getActivity()).load(Utils.getMapUrl(
                    Utils.getDisplayWidth(getActivity()),
                    getResources().getDimensionPixelSize(R.dimen.map_height),
                    mPlace.getLocation(),
                    mLocation,
                    MAP_ZOOMLEVEL)).into(mMap);
        } else {
            mMap.setImageResource(0);
        }

        double mapMeters = getResources().getDimensionPixelSize(R.dimen.scalebar_width) * Utils.getMetersPerPixelForGoogleStaticMaps(mLocation, MAP_ZOOMLEVEL);
        mScaleBar.setText(Utils.formatDistance(getActivity(), mapMeters));

        mDescriptionSeparator.setText(getString(R.string.description_separator));
        String placeDescription = mPlace != null && mPlace.beskrivelse != null ? mPlace.beskrivelse : getString(R.string.unknown_place_description);
        SpannableString formattedDescription = new SpannableString(Html.fromHtml(placeDescription));
        mDescriptionText.setText(formattedDescription, TextView.BufferType.SPANNABLE);

        mHomepageSeparator.setText(getString(R.string.homepage_separator));
        mHomepageText.setMovementMethod(LinkMovementMethod.getInstance());
        mHomepageText.setText(Html.fromHtml(getString(R.string.more_on_homepage)));
        String homepageUrl = mPlace != null ? mPlace.getHomePageUrl() : null;
        String homepageLinkedText = getString(R.string.no_homepage);
        if (homepageUrl != null) {
            homepageLinkedText = getString(R.string.more_on_homepage, homepageUrl);
        }
        mHomepageText.setText(Html.fromHtml(homepageLinkedText));

        mCheckinSeparator.setText(getString(R.string.checkin_separator_title));
        mCheckinText.setText(getCheckinStatsString());
    }

    private void setPlace(Place place) {
        mPlace = place;
        mPlaceAdapter.setPlaces(Collections.singletonList(place));
        updateView();
    }

    private String getCheckinStatsString() {
        return getString(R.string.checkin_data_missing);
    }

    @Override
    public void onCheckin(PlaceCheckin checkin) {
        fetchUserCheckins();
    }
}
