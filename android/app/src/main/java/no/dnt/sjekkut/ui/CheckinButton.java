package no.dnt.sjekkut.ui;

import android.content.Context;
import android.content.res.ColorStateList;
import android.location.Location;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.ProjectList;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.UserCheckins;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import timber.log.Timber;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 02.09.2016.
 */

public class CheckinButton extends RelativeLayout implements View.OnClickListener {

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
    private UserCheckins mUserCheckins;
    private final Callback<Project> mProjectCallback = createProjectCallback();
    private final Callback<ProjectList> mProjectListCallback = createProjectListCallback();
    private final Callback<UserCheckins> mUserCheckinsCallback = createUserCheckinsCallback();

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
            String label = "";
            String info = "";
            Place nearestPlace = findNearestPlace();
            if (nearestPlace != null) {
                label = Utils.formatDistance(getContext(), nearestPlace.getDistanceTo(mLocation));
                info = getContext().getString(R.string.nearest_place_is, nearestPlace.navn);
            }
            mLabel.setText(label);
            mInfo.setText(info);
            if (mUserCheckins != null && !mUserCheckins.getVisitedPlaceIds().isEmpty()) {
                mButton.setBackgroundTintList(ColorStateList.valueOf(ContextCompat.getColor(getContext(), R.color.todo)));
            } else {
                mButton.setBackgroundTintList(ColorStateList.valueOf(ContextCompat.getColor(getContext(), R.color.dntBlue)));
            }
        }
    }

    private void inflateView(Context context) {
        LayoutInflater inflater = (LayoutInflater) context
                .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.layout_checkinbutton, this);
        ButterKnife.bind(this);
        mButton.setOnClickListener(this);
        ViewCompat.setElevation(mInfo, mButton.getCompatElevation());
        ViewCompat.setElevation(mLabel, mButton.getCompatElevation());
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        updateView();
        Timber.i("CheckinButton is calling shit");
        CheckinApiSingleton.call().getUserCheckins(
                PreferenceUtils.getUserId(getContext()),
                PreferenceUtils.getAccessToken(getContext()),
                PreferenceUtils.getUserId(getContext()))
                .enqueue(mUserCheckinsCallback);
        TripApiSingleton.call().getProjectList(
                getContext().getString(R.string.api_key),
                TripApiSingleton.PROJECTLIST_FIELDS)
                .enqueue(mProjectListCallback);
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.fabButton:
                mInfo.setVisibility(View.VISIBLE);
                mHandler.removeCallbacksAndMessages(null);
                mHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        mInfo.setVisibility(View.INVISIBLE);
                    }
                }, 2000);
                break;
        }
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
}
