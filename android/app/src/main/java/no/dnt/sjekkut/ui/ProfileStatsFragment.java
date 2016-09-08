package no.dnt.sjekkut.ui;

import android.content.Context;
import android.location.Location;
import android.os.Bundle;
import android.support.v4.content.ContextCompat;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import butterknife.BindView;
import butterknife.BindViews;
import butterknife.ButterKnife;
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


public class ProfileStatsFragment extends LocationFragment implements View.OnClickListener {

    private static final int MERIT_TOTAL_VISITS = 0;
    private static final int MERIT_PROJECT_COUNT = 1;
    private static final int MERIT_VISITS_LAST_30 = 2;
    private static final long THIRTY_DAYS_MS = 2592000000L;
    @BindView(R.id.visitlist)
    RecyclerView mRecyclerView;
    @BindView(R.id.username)
    TextView mUsername;
    @BindView(R.id.toolbar)
    Toolbar mToolbar;
    @BindViews({R.id.statlayout_1, R.id.statlayout_2, R.id.statlayout_3})
    List<View> mStatCountLayouts;
    @BindView(R.id.logout)
    Button mLogout;
    @BindView(R.id.visits_separator)
    TextView mVisitsSeparator;
    @BindView(R.id.merits_separator)
    TextView mMeritsSeparator;
    @BindView(R.id.checkinButton)
    CheckinButton mCheckinButton;

    private List<StatCountHolder> mStatCountHolders = new ArrayList<>();
    private PlaceVisitAdapter mPlaceVisitAdapter;
    private ProfileStatsListener mListener;
    private Callback<UserCheckins> mUserCheckinsCallback;
    private Callback<Place> mPlaceCallback;

    public ProfileStatsFragment() {
        mUserCheckinsCallback = new Callback<UserCheckins>() {
            @Override
            public void onResponse(Call<UserCheckins> call, Response<UserCheckins> response) {
                if (response.isSuccessful()) {
                    mPlaceVisitAdapter.setUserCheckins(response.body());
                    updateMeritsView(response.body());
                    for (String placeId : response.body().getVisitedPlaceIds()) {
                        TripApiSingleton.call().getPlace(placeId,
                                getString(R.string.api_key),
                                TripApiSingleton.PLACE_EXPAND)
                                .enqueue(mPlaceCallback);
                    }
                } else {
                    Utils.showToast(getContext(), "Failed to get user checkins: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<UserCheckins> call, Throwable t) {
                Utils.showToast(getContext(), "Failed to get user checkins: " + t);
            }
        };

        mPlaceCallback = new Callback<Place>() {
            @Override
            public void onResponse(Call<Place> call, Response<Place> response) {
                if (response.isSuccessful()) {
                    mPlaceVisitAdapter.updatePlace(response.body());
                } else {
                    Utils.showToast(getContext(), "Failed to get place: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<Place> call, Throwable t) {
                Utils.showToast(getContext(), "Failed to get place: " + t);
            }
        };
    }

    public static ProfileStatsFragment newInstance() {
        return new ProfileStatsFragment();
    }

    private void updateMeritsView(UserCheckins userCheckins) {
        String totalVisits = "0";
        String totalProjects = "0";
        String visitsLast30 = "0";
        if (userCheckins != null) {
            totalVisits = Integer.toString(userCheckins.getTotalNumberOfVisits());
            totalProjects = Integer.toString(userCheckins.getNumberOfProjects());
            visitsLast30 = Integer.toString(userCheckins.getNumberOfVisitsAfter(new Date().getTime() - THIRTY_DAYS_MS));
        }
        for (int i = 0; i < mStatCountHolders.size(); ++i) {
            StatCountHolder holder = mStatCountHolders.get(i);
            switch (i) {
                case MERIT_TOTAL_VISITS:
                    holder.counter.setText(totalVisits);
                    break;
                case MERIT_PROJECT_COUNT:
                    holder.counter.setText(totalProjects);
                    break;
                case MERIT_VISITS_LAST_30:
                    holder.counter.setText(visitsLast30);
                    break;
                default:
                    holder.counter.setText("");
                    break;
            }
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_profilestats, container, false);
        ButterKnife.bind(this, view);
        Context context = view.getContext();
        Utils.setupSupportToolbar(getActivity(), mToolbar, getString(R.string.screen_profile), true);
        for (View layout : mStatCountLayouts) {
            mStatCountHolders.add(new StatCountHolder(layout));
        }
        for (int i = 0; i < mStatCountHolders.size(); ++i) {
            StatCountHolder holder = mStatCountHolders.get(i);
            holder.label.setText(getMeritLabel(i));
            holder.circle.setColorFilter(getMeritColor(i));
        }
        mUsername.setText(PreferenceUtils.getUserFullname(context));
        mMeritsSeparator.setText(getString(R.string.your_merits));
        mVisitsSeparator.setText(getString(R.string.your_visits));
        mRecyclerView.setLayoutManager(new LinearLayoutManager(context));
        mPlaceVisitAdapter = new PlaceVisitAdapter(mListener);
        mRecyclerView.setAdapter(mPlaceVisitAdapter);
        mLogout.setOnClickListener(this);
        setHasOptionsMenu(true);
        return view;
    }

    private int getMeritColor(int merit) {
        switch (merit) {
            case MERIT_TOTAL_VISITS:
                return ContextCompat.getColor(getContext(), R.color.dntRed);
            case MERIT_PROJECT_COUNT:
                return ContextCompat.getColor(getContext(), R.color.todo);
            case MERIT_VISITS_LAST_30:
                return ContextCompat.getColor(getContext(), R.color.dntBlue);
            default:
                return ContextCompat.getColor(getContext(), R.color.todo);
        }
    }

    private String getMeritLabel(int merit) {
        switch (merit) {
            case MERIT_TOTAL_VISITS:
                return getContext().getString(R.string.merit_total_visits);
            case MERIT_PROJECT_COUNT:
                return getContext().getString(R.string.merit_number_of_projects);
            case MERIT_VISITS_LAST_30:
                return getContext().getString(R.string.merit_visits_last_30days);
            default:
                return "";
        }
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof ProfileStatsListener) {
            mListener = (ProfileStatsListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement ProfileStatsListener");
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        CheckinApiSingleton.call().getUserCheckins(
                PreferenceUtils.getUserId(getContext()),
                PreferenceUtils.getAccessToken(getContext()),
                PreferenceUtils.getUserId(getContext()))
                .enqueue(mUserCheckinsCallback);
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
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.logout:
                if (mListener != null) {
                    mListener.onLogout();
                }
                break;
        }
    }

    @Override
    public void onLocationChanged(Location location) {
        mCheckinButton.setLocation(location);
    }

    interface ProfileStatsListener extends PlaceClickedListener {
        void onLogout();
    }

    static class StatCountHolder {
        @BindView(R.id.circle)
        ImageView circle;
        @BindView(R.id.counter)
        TextView counter;
        @BindView(R.id.label)
        TextView label;

        StatCountHolder(View view) {
            ButterKnife.bind(this, view);
        }
    }
}
