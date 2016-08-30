package no.dnt.sjekkut.ui;

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
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
import java.util.List;

import butterknife.BindView;
import butterknife.BindViews;
import butterknife.ButterKnife;
import no.dnt.sjekkut.PreferenceUtils;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.network.CheckinApiSingleton;
import no.dnt.sjekkut.network.LoginApiSingleton;
import no.dnt.sjekkut.network.MemberData;
import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.TripApiSingleton;
import no.dnt.sjekkut.network.UserCheckins;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;


public class ProfileStatsFragment extends Fragment implements View.OnClickListener {

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
    private List<StatCountHolder> mStatCountHolders = new ArrayList<>();
    private PlaceVisitAdapter mPlaceVisitAdapter;

    private ProfileStatsListener mListener;
    private Callback<MemberData> mMemberCallback;
    private Callback<UserCheckins> mUserCheckinsCallback;
    private Callback<Place> mPlaceCallback;

    public ProfileStatsFragment() {
        mMemberCallback = new Callback<MemberData>() {
            @Override
            public void onResponse(Call<MemberData> call, Response<MemberData> response) {
                if (response.isSuccessful()) {
                    mUsername.setText(response.body().getFullname());
                } else {
                    mUsername.setText(getString(R.string.username_unknown));
                    Utils.showToast(getContext(), "Failed to get member data: " + response.code());
                }
            }

            @Override
            public void onFailure(Call<MemberData> call, Throwable t) {
                mUsername.setText(getString(R.string.username_unknown));
                Utils.showToast(getContext(), "Failed to get member data: " + t);
            }
        };

        mUserCheckinsCallback = new Callback<UserCheckins>() {
            @Override
            public void onResponse(Call<UserCheckins> call, Response<UserCheckins> response) {
                if (response.isSuccessful()) {
                    mPlaceVisitAdapter.setUserCheckins(response.body());
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
        for (StatCountHolder holder : mStatCountHolders) {
            holder.label.setText("Antall foo");
            holder.counter.setText(Integer.toString((int) (Math.random() * 10)));
            holder.circle.setColorFilter(ContextCompat.getColor(context, R.color.todo));
        }
        mRecyclerView.setLayoutManager(new LinearLayoutManager(context));
        mPlaceVisitAdapter = new PlaceVisitAdapter();
        mRecyclerView.setAdapter(mPlaceVisitAdapter);
        mLogout.setOnClickListener(this);
        setHasOptionsMenu(true);
        return view;
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
        LoginApiSingleton.call().getMember(PreferenceUtils.getBearerAuthorization(getContext())).enqueue(mMemberCallback);
        CheckinApiSingleton.call().getUserCheckins(PreferenceUtils.getUserId(getContext())).enqueue(mUserCheckinsCallback);
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

    interface ProfileStatsListener {
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
