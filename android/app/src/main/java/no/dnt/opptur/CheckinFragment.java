package no.dnt.opptur;

import android.content.res.Resources;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.support.v7.app.ActionBarActivity;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;
import com.squareup.picasso.Picasso;

import java.util.Date;
import java.util.List;

import retrofit.Callback;
import retrofit.RetrofitError;
import retrofit.client.Response;

/**
 * Copyright Den Norske Turistforening 2015
 * <p/>
 * Created by espen on 05.02.2015.
 */
public class CheckinFragment extends Fragment implements LocationListener, View.OnClickListener {


    private final static String BUNDLE_MOUNTAIN = "BUNDLE_MOUNTAIN";
    private final static long CHECKIN_TIMESPAN_THRESHOLD_MILLISECONDS = 24*60*60*1000;
    private final static float CHECKIN_DISTANCE_THRESHOLD_METERS = 200.0f;
    private final static int MAP_ZOOMLEVEL = 14;

    private final LocationRequest mLocationRequest;

    private Location mLocation;
    private Mountain mMountain;
    private Checkin mCheckin;
    private Checkin.Statistics mStatistics;

    private final Callback<List<Mountain>> mListMountainsCallback;
    private final Callback<Checkin> mCheckinToMountainCallback;
    private final Callback<List<Checkin>> mListCheckinsCallback;
    private final Callback<Checkin.Statistics> mGetStatisticsCallback;
    private int mCallbackRefCount = 0;
    private String mCallbackDescription = "";

    public static CheckinFragment newInstance(Mountain mountain) {
        CheckinFragment fragment = new CheckinFragment();
        Bundle args = new Bundle();
        args.putSerializable(BUNDLE_MOUNTAIN, mountain);
        fragment.setArguments(args);
        return fragment;
    }

    public CheckinFragment() {
        mLocationRequest = LocationRequest.create();
        mLocationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
        mLocationRequest.setFastestInterval(500);
        mLocationRequest.setInterval(1000);
        mLocationRequest.setSmallestDisplacement(0);
        mLocationRequest.setNumUpdates(1);

        mListMountainsCallback = new Callback<List<Mountain>>() {
            @Override
            public void success(List<Mountain> mountains, Response response) {
                --mCallbackRefCount;
                if (getView() == null)
                    return;

                setMountain(getClosestMountain(mLocation, mountains));
                callCheckinToMountain();
            }

            @Override
            public void failure(RetrofitError error) {
                --mCallbackRefCount;
                if (getView() == null)
                    return;

                Utils.showToast(getActivity(), getString(R.string.checkin_no_mountain));
                updateView();
            }
        };

        mCheckinToMountainCallback = new Callback<Checkin>() {
            @Override
            public void success(Checkin checkin, Response response) {
                --mCallbackRefCount;
                if (getView() == null)
                    return;

                fetchCheckinsAndStatistics();
            }

            @Override
            public void failure(RetrofitError error) {
                --mCallbackRefCount;
                if (getView() == null)
                    return;

                ServerError serverError = (ServerError) error.getBodyAs(ServerError.class);
                String errorString = (serverError != null && serverError.details != null) ? serverError.details : error.getMessage();
                Utils.showToast(getActivity(), errorString);
                updateView();
            }
        };

        mListCheckinsCallback = new Callback<List<Checkin>>() {
            @Override
            public void success(List<Checkin> checkins, Response response) {
                --mCallbackRefCount;
                if (getView() == null)
                    return;

                setCheckin(Utils.getLatestCheckin(checkins, mMountain));
                updateView();
            }

            @Override
            public void failure(RetrofitError error) {
                --mCallbackRefCount;
                if (getView() == null)
                    return;

                setCheckin(null);
                Utils.showToast(getActivity(), getString(R.string.error_did_not_find_checkins));
                updateView();
            }
        };


        mGetStatisticsCallback = new Callback<Checkin.Statistics>() {
            @Override
            public void success(Checkin.Statistics statistics, Response response) {
                --mCallbackRefCount;
                if (getView() == null)
                    return;

                setStatistics(statistics);
            }

            @Override
            public void failure(RetrofitError error) {
                --mCallbackRefCount;
                if (getView() == null)
                    return;

                Utils.showToast(getActivity(), getString(R.string.error_did_not_find_statistics));
                setStatistics(null);
            }
        };
    }

    private void popFragment() {
        if (getActivity() instanceof MainActivity) {
            getActivity().getSupportFragmentManager().popBackStack();
        }
    }


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        setHasOptionsMenu(true);
        return inflater.inflate(R.layout.fragment_checkin, container, false);
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        if (mCheckin != null) {
            inflater.inflate(R.menu.menu_share, menu);
        }
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        setMountain((Mountain) getArguments().getSerializable(BUNDLE_MOUNTAIN));

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
    public void onLocationChanged(Location location) {
        --mCallbackRefCount;
        mLocation = location;
        if (isAdded()) {
            if (mLocation == null) {
                Utils.showToast(getActivity(), getString(R.string.error_did_not_find_position));
                updateView();
            } else if (mMountain == null) {
                OppturApi.getService().listMountains(mListMountainsCallback);
                ++mCallbackRefCount;
                mCallbackDescription = getString(R.string.callback_finding_closest_mountain);
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

        boolean timespanOK = mCheckin == null || (new Date().getTime() - mCheckin.timestamp.getTime()) > CHECKIN_TIMESPAN_THRESHOLD_MILLISECONDS;
        boolean distanceOK = mMountain != null && mLocation != null && mLocation.distanceTo(mMountain.getLocation()) < CHECKIN_DISTANCE_THRESHOLD_METERS;
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
            String mountainName = mMountain != null ? mMountain.name : getString(R.string.unknown_mountain_name);
            name.setText(mountainName);
        }
        TextView countyAndHeight = (TextView) getView().findViewById(R.id.county_and_height);
        if (countyAndHeight != null) {
            String county = mMountain != null ? mMountain.county : getString(R.string.unknown_mountain_county);
            double height = mMountain != null ? mMountain.height : 0.0d;
            countyAndHeight.setText(getString(R.string.county_and_height, county, height));
        }
        TextView summits = (TextView) getView().findViewById(R.id.summits);
        if (summits != null) {
            int count = mMountain != null ? mMountain.checkinCount : 0;
            summits.setText(getString(R.string.summits, count));
        }
        TextView distance = (TextView) getView().findViewById(R.id.distance);
        if (distance != null) {
            String distanceText = mMountain != null && mLocation != null ?
                    Utils.formatDistance(getActivity(), mLocation.distanceTo(mMountain.getLocation())) : "n/a";
            distance.setText(getString(R.string.distance_to_you, distanceText));
        }
        ImageView image = (ImageView) getView().findViewById(R.id.image);
        if (image != null) {
            if (mMountain != null) {
                Picasso.with(getActivity()).load(mMountain.getImageUrl()).fit().centerCrop().into(image);
            } else {
                image.setImageResource(0);
            }
        }
        ImageView map = (ImageView) getView().findViewById(R.id.map);
        if (map != null) {
            if (mMountain != null) {
                Picasso.with(getActivity()).load(mMountain.getMapUrl(Utils.getDisplayWidth(getActivity()), getResources().getDimensionPixelSize(R.dimen.map_height), mLocation, MAP_ZOOMLEVEL)).into(map);
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
                checkinButton.setTag(R.id.tag_mountain_id, mMountain != null ? mMountain.id : null);
                checkinButton.setTextColor(getResources().getColor(R.color.white));
            } else {
                checkinButton.setText(getString(R.string.checkin_back));
                Utils.setColorFilter(checkinButton, getResources().getColor(R.color.dntLightGray));
                checkinButton.setTag(R.id.tag_mountain_id, null);
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
            String mountainDescription = mMountain != null ? mMountain.description : getString(R.string.unknown_mountain_description);
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

    private void setMountain(Mountain mountain) {
        mMountain = mountain;
        Utils.setActionBarTitle(getActivity(), mMountain != null && mMountain.name != null ? mMountain.name : "");
        fetchCheckinsAndStatistics();
    }

    private void setCheckin(Checkin checkin) {
        mCheckin = checkin;
        if (getActivity() instanceof ActionBarActivity) {
            getActivity().supportInvalidateOptionsMenu();
        }
        updateView();
    }

    private void setStatistics(Checkin.Statistics statistics) {
        mStatistics = statistics;
        updateView();
    }

    public static Mountain getClosestMountain(Location location, List<Mountain> mountains) {
        if (location == null || mountains == null || mountains.isEmpty()) {
            return null;
        }

        float closestDistance = Float.MAX_VALUE;
        Mountain closestMountain = null;
        for (Mountain mountain : mountains) {
            float distance = mountain.getLocation().distanceTo(location);
            if (distance < closestDistance) {
                closestMountain = mountain;
                closestDistance = distance;
            }
        }
        return closestMountain;
    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.checkin:
                Long mountainID = (Long) view.getTag(R.id.tag_mountain_id);
                if (mountainID != null) {
                    callCheckinToMountain();
                } else {
                    popFragment();
                }
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.share:
                Utils.shareCheckin(getActivity(), mCheckin, mMountain);
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    private void callCheckinToMountain() {
        OppturApi.getService().checkinToMountain(
                mMountain.id,
                Utils.getDeviceID(getActivity()),
                new OppturApi.CheckinBody(mLocation),
                mCheckinToMountainCallback);
        ++mCallbackRefCount;
        mCallbackDescription = getString(R.string.callback_checkin_in);
        updateView();
    }

    private void fetchCheckinsAndStatistics() {
        OppturApi.getService().listCheckins(Utils.getDeviceID(getActivity()), mListCheckinsCallback);
        ++mCallbackRefCount;
        if (mMountain != null) {
            OppturApi.getService().getMountainStatistics(mMountain.id, Utils.getDeviceID(getActivity()), mGetStatisticsCallback);
            ++mCallbackRefCount;
        }
        mCallbackDescription = getString(R.string.callback_checkins_and_statistics);
        updateView();
    }

    private String getCheckinStatsString() {
        if (mMountain == null)
            return getString(R.string.checkin_data_missing);

        StringBuilder builder = new StringBuilder();
        if (mCheckin != null) {
            builder.append(getString(R.string.checkin_success, mMountain.name, Utils.getTimeSpanFromNow(mCheckin.timestamp)));
            builder.append(" ");
        }
        if (mStatistics != null) {
            Resources res = getResources();
            builder.append(Utils.getQuantityStringWithZero(res, R.plurals.checkin_personal_count, R.string.checkin_personal_count_zero, mStatistics.personalCount))
                    .append(" ")
                    .append(Utils.getQuantityStringWithZero(res, R.plurals.checkin_daily_count, R.string.checkin_dailycount_zero, mStatistics.dailyCount))
                    .append(" ")
                    .append(Utils.getQuantityStringWithZero(res, R.plurals.checkin_total_count, R.string.checkin_total_count_zero, mStatistics.totalCount));
        }
        return builder.toString();
    }
}
