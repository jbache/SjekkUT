package no.dnt.sjekkut;

import android.content.DialogInterface;
import android.location.Location;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.ListFragment;
import android.support.v7.app.AlertDialog;
import android.text.Html;
import android.text.method.LinkMovementMethod;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;
import com.squareup.picasso.Picasso;

import org.apache.http.HttpStatus;

import java.util.ArrayList;
import java.util.List;

import retrofit.Callback;
import retrofit.RetrofitError;
import retrofit.client.Response;

/**
 * Copyright Den Norske Turistforening 2015
 * <p/>
 * Created by espen on 05.02.2015.
 */
public class SummitListFragment extends ListFragment implements LocationListener, View.OnClickListener, DialogInterface.OnClickListener {

    private MountainAdapter mMountainAdapter;
    private final List<Checkin> mCheckins;
    private final Callback<List<Mountain>> mListMountainsCallback;
    private final Callback<List<Checkin>> mListCheckinsCallback;
    private final Callback<List<Challenge>> mListChallengesCallback;
    private final Callback<User> mRegisterUserCallback;
    private final Callback<Challenge> mJoinChallengeCallback;
    private final LocationRequest mLocationRequest;
    private Challenge mChallenge;
    private Location mLastLocation = null;
    private View mHeaderView;
    private AlertDialog mNameEmailDialog;

    public SummitListFragment() {
        mCheckins = new ArrayList<>();
        mLocationRequest = LocationRequest.create();
        mLocationRequest.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
        mLocationRequest.setInterval(10000);
        mLocationRequest.setSmallestDisplacement(20);
        mListMountainsCallback = new Callback<List<Mountain>>() {

            @Override
            public void success(List<Mountain> mountains, Response response) {
                if (getView() == null)
                    return;

                mMountainAdapter.setNotifyOnChange(false);
                mMountainAdapter.clear();
                mMountainAdapter.addAll(mountains);
                mMountainAdapter.sortByDistance(mLastLocation);
                mMountainAdapter.setNotifyOnChange(true);
                mMountainAdapter.notifyDataSetChanged();
                setListShown(true);
                OppturApi.getService().listCheckins(Utils.getDeviceID(getActivity()), mListCheckinsCallback);
            }

            @Override
            public void failure(RetrofitError error) {
                if (getView() == null)
                    return;

                setListShown(true);
                setEmptyText(getString(R.string.no_mountains_found));
            }
        };

        mListCheckinsCallback = new Callback<List<Checkin>>() {
            @Override
            public void success(List<Checkin> checkins, Response response) {
                if (getView() == null)
                    return;

                mCheckins.clear();
                mCheckins.addAll(checkins);
                getListView().invalidateViews();
            }

            @Override
            public void failure(RetrofitError error) {
                if (getView() == null)
                    return;

                mCheckins.clear();
                getListView().invalidateViews();
            }
        };
        mListChallengesCallback = new Callback<List<Challenge>>() {
            @Override
            public void success(List<Challenge> challenges, Response response) {
                if (getView() == null)
                    return;

                if (challenges.size() > 0)
                    mChallenge = challenges.get(challenges.size() - 1);
                updateHeader();
            }

            @Override
            public void failure(RetrofitError error) {
                mChallenge = null;
                updateHeader();
            }
        };
        mRegisterUserCallback = new Callback<User>() {
            @Override
            public void success(User user, Response response) {
                if (getView() == null)
                    return;

                Utils.showToast(getActivity(), "Bruker: " + user.name + " ble registrert");
                if (mChallenge != null) {
                    OppturApi.getService().joinChallenge(mChallenge.id, Utils.getDeviceID(getActivity()), mJoinChallengeCallback);
                }
            }

            @Override
            public void failure(RetrofitError error) {
                if (getView() == null)
                    return;

                if (error.getResponse().getStatus() == HttpStatus.SC_FORBIDDEN) {
                    OppturApi.getService().joinChallenge(mChallenge.id, Utils.getDeviceID(getActivity()), mJoinChallengeCallback);
                }
                ServerError details = (ServerError) error.getBodyAs(ServerError.class);
                Utils.showToast(getActivity(), details != null ? details.details : error.getMessage());
            }
        };
        mJoinChallengeCallback = new Callback<Challenge>() {
            @Override
            public void success(Challenge challenge, Response response) {
                if (getView() == null)
                    return;

                Utils.showToast(getActivity(), getString(R.string.challenge_joined_toast, challenge.title));
                mChallenge = challenge;
                updateHeader();
            }

            @Override
            public void failure(RetrofitError error) {
                ServerError details = (ServerError) error.getBodyAs(ServerError.class);
                Utils.showToast(getActivity(), details != null ? details.details : error.getMessage());
                updateHeader();
            }
        };
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View defaultListView = super.onCreateView(inflater, container, savedInstanceState);
        View rootView = inflater.inflate(R.layout.fragment_summitlist, container, false);
        LinearLayout listContainer = (LinearLayout) rootView.findViewById(R.id.listContainer);
        if (listContainer != null && defaultListView != null) {
            listContainer.addView(defaultListView);
        }
        View fabButton = rootView.findViewById(R.id.fab);
        if (fabButton != null) {
            fabButton.setOnClickListener(this);
        }
        setHasOptionsMenu(true);
        return rootView;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        setListAdapter(null);
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.menu_feedback, menu);
        super.onCreateOptionsMenu(menu, inflater);
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        if (mHeaderView == null) {
            mHeaderView = getLayoutInflater(savedInstanceState).inflate(R.layout.header_challenge, getListView(), false);
            View text = mHeaderView.findViewById(R.id.text);
            if (text != null) {
                text.setOnClickListener(this);
            }
        }
        getListView().addHeaderView(mHeaderView, null, false);
        mMountainAdapter = new MountainAdapter(getActivity(), mCheckins);
        setListAdapter(mMountainAdapter);
        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).startLocationUpdates(this, mLocationRequest);
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        Utils.toggleUpButton(getActivity(), false);
        Utils.setActionBarTitle(getActivity(), getString(R.string.app_name));
        fetchMountains();
        fetchChallenges();
    }

    private void fetchMountains() {
        if (mMountainAdapter.getCount() == 0) {
            setListShown(false);
            OppturApi.getService().listMountains(mListMountainsCallback);
        }
    }

    private void fetchChallenges() {
        OppturApi.getService().listChallenges(Utils.getDeviceID(getActivity()), mListChallengesCallback);
    }

    private void promptForNameAndEmail() {
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity(), R.style.AppDialogStyle);
        builder.setTitle(getString(R.string.dialog_name_and_email_title));
        builder.setMessage(getString(R.string.dialog_name_and_email_message));
        builder.setView(R.layout.dialog_name_and_email);
        builder.setPositiveButton(getString(R.string.okbutton), this);
        builder.setNegativeButton(getString(R.string.cancelbutton), null);
        mNameEmailDialog = builder.create();
        mNameEmailDialog.show();
    }

    private void updateHeader() {
        if (getView() == null || getListView() == null || mHeaderView == null) {
            return;
        }

        String logoUrl = mChallenge == null ? null : mChallenge.logoUrl;
        String footerUrl = mChallenge == null ? null : mChallenge.footerUrl;
        String url = mChallenge == null ? null : mChallenge.url;

        View logo = mHeaderView.findViewById(R.id.logo);
        if (logo instanceof ImageView) {
            Picasso.with(getActivity()).load(logoUrl).fit().centerInside().into((ImageView) logo);
        }
        View readMore = mHeaderView.findViewById(R.id.readmore);
        if (readMore instanceof TextView) {
            String urlString = "";
            if (url != null) {
                urlString = "<a href=\"" + url + "\">" + getString(R.string.challenge_readmore) + "</a>";
            }
            ((TextView) readMore).setText(Html.fromHtml(urlString));
            ((TextView) readMore).setMovementMethod(LinkMovementMethod.getInstance());
        }
        View text = mHeaderView.findViewById(R.id.text);
        if (text instanceof TextView) {
            if (mChallenge != null) {
                if (mChallenge.joined) {
                    if (mChallenge.mountains == null) {
                        ((TextView) text).setText(getString(R.string.challenge_joined_progress, mChallenge.userProgress));
                    } else if (mChallenge.userProgress < mChallenge.mountains.size()) {
                        ((TextView) text).setText(getString(R.string.challenge_joined_progress_of_total, mChallenge.userProgress, mChallenge.mountains.size()));
                    } else {
                        ((TextView) text).setText(getString(R.string.challenge_joined_completed, mChallenge.mountains.size()));
                    }
                } else {
                    ((TextView) text).setText(Html.fromHtml(getString(R.string.challenge_joined_pleasejoin)));
                }
            } else {
                ((TextView) text).setText("");
            }
        }
        View footer = mHeaderView.findViewById(R.id.footer);
        if (footer instanceof ImageView) {
            Picasso.with(getActivity()).load(footerUrl).into((ImageView) footer);
        }
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.fab:
                getActivity().getSupportFragmentManager().beginTransaction()
                        .replace(R.id.container, CheckinFragment.newInstance(null))
                        .addToBackStack(CheckinFragment.class.getCanonicalName())
                        .commit();
                break;
            case R.id.text:
                if (mChallenge != null && !mChallenge.joined) {
                    promptForNameAndEmail();
                }
                break;
        }
    }

    @Override
    public void onListItemClick(ListView l, View v, int position, long id) {
        Mountain mountain = (Mountain) getListView().getItemAtPosition(position);
        getActivity().getSupportFragmentManager().beginTransaction()
                .replace(R.id.container, CheckinFragment.newInstance(mountain))
                .addToBackStack(CheckinFragment.class.getCanonicalName())
                .commit();
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

    public void onLocationChanged(Location location) {
        mLastLocation = location;
        mMountainAdapter.sortByDistance(mLastLocation);
    }

    @Override
    public void onClick(DialogInterface dialog, int which) {
        if (which == DialogInterface.BUTTON_POSITIVE && mNameEmailDialog != null) {
            View nameEdit = mNameEmailDialog.findViewById(R.id.name);
            View emailEdit = mNameEmailDialog.findViewById(R.id.email);
            if (nameEdit instanceof EditText && emailEdit instanceof EditText) {
                String name = ((EditText) nameEdit).getText().toString();
                String email = ((EditText) emailEdit).getText().toString();
                OppturApi.getService().registerUser(Utils.getDeviceID(getActivity()), new User(name, email), mRegisterUserCallback);
            }
        }
    }
}
