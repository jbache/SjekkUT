package no.dnt.sjekkut.ui;

import android.animation.LayoutTransition;
import android.animation.ObjectAnimator;
import android.animation.PropertyValuesHolder;
import android.content.Context;
import android.content.res.ColorStateList;
import android.location.Location;
import android.os.Build;
import android.os.Handler;
import android.support.design.widget.FloatingActionButton;
import android.support.v4.content.ContextCompat;
import android.support.v4.view.ViewCompat;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.RelativeLayout;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.CheckinLocation;
import no.dnt.sjekkut.network.CheckinResult;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.PlaceCheckin;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.ProjectList;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.UserCheckins;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 02.09.2016.
 */

public class CheckinButton extends RelativeLayout implements View.OnClickListener {

    private static final double CHECKIN_MAX_DISTANCE_METERS = 200.0d; // 200 meters
    private static final long CHECKIN_MIN_DELTA_MS = 1000 * 60 * 60 * 24; // 24 hrs in milliseconds
    private final Handler mHandler = new Handler();
    private final Map<String, Place> mPlaceMap = new HashMap<>();
    @BindView(R.id.fabButton)
    FloatingActionButton mButton;
    @BindView(R.id.fabButtonText)
    TextView mLabel;
    @BindView(R.id.fabInfoText)
    TextView mInfo;
    private Location mLocation;
    private final Comparator<Place> mComparator = createComparator();
    private StringProvider mInfoProvider;
    private UserCheckins mUserCheckins;
    private final Callback<Project> mProjectCallback = createProjectCallback();
    private final Callback<ProjectList> mProjectListCallback = createProjectListCallback();
    private final Callback<UserCheckins> mUserCheckinsCallback = createUserCheckinsCallback();
    private Call<CheckinResult> mCheckinCall;
    private CheckinListener mListener;
    private final Callback<CheckinResult> mCheckinResultCallback = createCheckinResultCallback();
    private final Long DEFAULT_HIDE_DELAY = 7000L;

    public CheckinButton(Context context) {
        super(context);
        inflateView(context);
    }

    public CheckinButton(Context context, AttributeSet attrs) {
        super(context, attrs);
        inflateView(context);
    }

    public CheckinButton(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        inflateView(context);
    }

    private Callback<CheckinResult> createCheckinResultCallback() {
        return new Callback<CheckinResult>() {
            @Override
            public void onResponse(Call<CheckinResult> call, Response<CheckinResult> response) {
                mCheckinCall = null;
                if (response.isSuccessful()) {
                    showInfo(getContext().getString(R.string.checkin_success), DEFAULT_HIDE_DELAY);
                    fetchUserCheckins();
                    if (mListener != null) {
                        mListener.onCheckin(response.body().data);
                    }
                } else {
                    showInfo(getContext().getString(R.string.checkin_failure), DEFAULT_HIDE_DELAY);
                    Utils.showToast(getContext(), "Failed to checkin: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<CheckinResult> call, Throwable t) {
                mCheckinCall = null;
                showInfo(getContext().getString(R.string.checkin_failure), DEFAULT_HIDE_DELAY);
                Utils.showToast(getContext(), "Failed to checkin: " + t);
            }
        };
    }

    private Comparator<Place> createComparator() {
        return new Comparator<Place>() {
            @Override
            public int compare(Place place1, Place place2) {
                int result = Utils.nullSafeCompareTo(place1.getDistanceTo(mLocation), place2.getDistanceTo(mLocation));
                if (result == 0) {
                    result = Utils.nullSafeCompareTo(place1.navn, place2.navn);
                }
                return result;
            }
        };
    }

    private Callback<Project> createProjectCallback() {
        return new Callback<Project>() {
            @Override
            public void onResponse(Call<Project> call, Response<Project> response) {
                if (response.isSuccessful()) {
                    for (Place place : response.body().steder) {
                        mPlaceMap.put(place._id, place);
                    }
                }
                updateView();
            }

            @Override
            public void onFailure(Call<Project> call, Throwable t) {
                updateView();
            }
        };
    }

    private Callback<ProjectList> createProjectListCallback() {
        return new Callback<ProjectList>() {
            @Override
            public void onResponse(Call<ProjectList> call, Response<ProjectList> response) {
                mPlaceMap.clear();
                if (response.isSuccessful()) {
                    for (Project project : response.body().documents) {
                        TripApiSingleton.call().getProject(
                                project._id,
                                getContext().getString(R.string.api_key),
                                TripApiSingleton.PROJECT_FIELDS,
                                TripApiSingleton.PROJECT_EXPAND)
                                .enqueue(mProjectCallback);
                    }
                }
                updateView();
            }

            @Override
            public void onFailure(Call<ProjectList> call, Throwable t) {
                mPlaceMap.clear();
                updateView();
            }
        };
    }

    private Callback<UserCheckins> createUserCheckinsCallback() {
        return new Callback<UserCheckins>() {
            @Override
            public void onResponse(Call<UserCheckins> call, Response<UserCheckins> response) {
                if (response.isSuccessful()) {
                    mUserCheckins = response.body();
                } else {
                    mUserCheckins = null;
                }
                updateView();
            }

            @Override
            public void onFailure(Call<UserCheckins> call, Throwable t) {
                mUserCheckins = null;
                updateView();
            }
        };
    }

    private void updateView() {
        if (ViewCompat.isAttachedToWindow(this)) {
            String label;
            String placeIdTag = null;
            int colorId = R.color.fabInfo;
            if (Utils.isAccurateGPSEnabled(getContext())) {
                if (mLocation != null) {
                    if (mUserCheckins != null) {
                        final Place nearestPlace = findNearestPlace();
                        if (nearestPlace != null) {
                            double distanceM = nearestPlace.getDistanceTo(mLocation);
                            if (distanceM > CHECKIN_MAX_DISTANCE_METERS) {
                                label = Utils.formatDistance(getContext(), distanceM);
                                mInfoProvider = staticProvider(getContext().getString(R.string.nearest_place_is, nearestPlace.navn));
                            } else {
                                final Date latest = getLatestCheckin(nearestPlace);
                                if (latest == null || new Date().getTime() - latest.getTime() > CHECKIN_MIN_DELTA_MS) {
                                    label = getContext().getString(R.string.register_visit);
                                    mInfoProvider = staticProvider(getContext().getString(R.string.visiting_nearest_place_is, nearestPlace.navn));
                                    placeIdTag = nearestPlace._id;
                                    colorId = R.color.fabVisit;
                                } else {
                                    label = getContext().getString(R.string.visit_registered);
                                    mInfoProvider = new StringProvider() {
                                        @Override
                                        public String getString() {
                                            return getContext().getString(
                                                    R.string.you_visited_place_at,
                                                    nearestPlace.navn,
                                                    Utils.getTimeSpanFromNow(
                                                            latest,
                                                            getContext().getString(R.string.just_now)));
                                        }
                                    };
                                }
                            }
                        } else {
                            label = getContext().getString(R.string.place_missing);
                            mInfoProvider = staticProvider(getContext().getString(R.string.cannot_locate_nearest_place));
                        }
                    } else {
                        label = getContext().getString(R.string.checkins_missing);
                        mInfoProvider = staticProvider(getContext().getString(R.string.user_checkins_missing));
                    }
                } else {
                    label = getContext().getString(R.string.position_missing);
                    mInfoProvider = staticProvider(getContext().getString(R.string.cannot_locate_your_position));
                }
            } else {
                label = getContext().getString(R.string.gps_missing);
                mInfoProvider = staticProvider(getContext().getString(R.string.gps_warning));
            }
            mLabel.setText(label);
            mButton.setTag(R.id.place_id, placeIdTag);
            mButton.setBackgroundTintList(ColorStateList.valueOf(ContextCompat.getColor(getContext(), colorId)));
        }
    }

    private StringProvider staticProvider(final String string) {
        return new StringProvider() {
            @Override
            public String getString() {
                return string;
            }
        };
    }

    private Date getLatestCheckin(Place place) {
        if (mUserCheckins != null && place != null) {
            PlaceCheckin checkin = mUserCheckins.getLatestCheckin(place._id);
            if (checkin != null) {
                return checkin.timestamp;
            }
        }
        return null;
    }

    private void inflateView(Context context) {
        LayoutInflater inflater = (LayoutInflater) context
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.layout_checkinbutton, this);
        ButterKnife.bind(this);
        mButton.setOnClickListener(this);
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            ViewCompat.setElevation(mInfo, context.getResources().getDimensionPixelSize(R.dimen.info_elevation));
            ViewCompat.setElevation(mLabel, context.getResources().getDimensionPixelSize(R.dimen.fab_elevation));
        }
        int displayWidth = Utils.getDisplayWidth(context);
        PropertyValuesHolder slideXIn = PropertyValuesHolder.ofFloat("translationX", displayWidth, 0);
        PropertyValuesHolder fadeIn = PropertyValuesHolder.ofFloat(ALPHA, 0, 1);
        PropertyValuesHolder slideXOut = PropertyValuesHolder.ofFloat("translationX", 0, displayWidth);
        PropertyValuesHolder fadeOut = PropertyValuesHolder.ofFloat(ALPHA, displayWidth, 1, 0);
        getLayoutTransition().setAnimator(LayoutTransition.APPEARING, ObjectAnimator.ofPropertyValuesHolder(this, slideXIn, fadeIn));
        getLayoutTransition().setAnimator(LayoutTransition.DISAPPEARING, ObjectAnimator.ofPropertyValuesHolder(this, slideXOut, fadeOut));
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        updateView();
        fetchUserCheckins();
        TripApiSingleton.call().getProjectList(
                getContext().getString(R.string.api_key),
                TripApiSingleton.PROJECTLIST_FIELDS)
                .enqueue(mProjectListCallback);
    }

    private void fetchUserCheckins() {
        CheckinApiSingleton.call().getUserCheckins(
                PreferenceUtils.getUserId(getContext()),
                PreferenceUtils.getAccessToken(getContext()),
                PreferenceUtils.getUserId(getContext()))
                .enqueue(mUserCheckinsCallback);
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.fabButton:
                boolean checkinStarted = postCheckin((String) v.getTag(R.id.place_id));
                boolean infoVisible = mInfo.getVisibility() == VISIBLE;
                if (infoVisible) {
                    hideInfo();
                } else {
                    String text = mInfoProvider != null ? mInfoProvider.getString() : "";
                    Long delayBeforeHide = checkinStarted ? null : DEFAULT_HIDE_DELAY;
                    showInfo(text, delayBeforeHide);
                }
                break;
        }
    }

    private void showInfo(String text, Long delayBeforeHide) {
        mHandler.removeCallbacksAndMessages(null);
        mInfo.setText(text);
        mInfo.setVisibility(View.VISIBLE);
        if (delayBeforeHide != null) {
            mHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    hideInfo();
                }
            }, 7000);
        }
    }

    private void hideInfo() {
        mHandler.removeCallbacksAndMessages(null);
        mInfo.setVisibility(View.INVISIBLE);
    }

    private boolean postCheckin(String placeId) {
        if (mCheckinCall != null || placeId == null)
            return false;

        mCheckinCall = CheckinApiSingleton.call().postPlaceCheckin(
                PreferenceUtils.getUserId(getContext()),
                PreferenceUtils.getAccessToken(getContext()),
                placeId,
                new CheckinLocation(mLocation));
        mCheckinCall.enqueue(mCheckinResultCallback);
        return false;
    }

    public void setLocation(Location location) {
        mLocation = location;
        updateView();
    }

    private Place findNearestPlace() {
        if (mLocation == null)
            return null;

        if (mPlaceMap.isEmpty())
            return null;

        List<Place> mPlaceList = new ArrayList<>(mPlaceMap.values());
        Collections.sort(mPlaceList, mComparator);

        return mPlaceList.get(0);
    }

    void setListener(CheckinListener listener) {
        mListener = listener;
    }

    interface CheckinListener {
        void onCheckin(PlaceCheckin checkin);
    }

    interface StringProvider {
        String getString();
    }
}
