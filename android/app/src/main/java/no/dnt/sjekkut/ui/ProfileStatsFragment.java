package no.dnt.sjekkut.ui;

import android.content.Context;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.Toolbar;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import butterknife.BindView;
import butterknife.ButterKnife;
import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;
import no.dnt.sjekkut.dummy.DummyContent;
import no.dnt.sjekkut.dummy.DummyContent.DummyItem;


public class ProfileStatsFragment extends Fragment {

    @BindView(R.id.visitlist)
    RecyclerView mRecyclerView;
    @BindView(R.id.username)
    TextView mUsername;
    @BindView(R.id.toolbar)
    Toolbar mToolbar;

    private ProfileStatsListener mListener;

    public ProfileStatsFragment() {
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
        mRecyclerView.setLayoutManager(new LinearLayoutManager(context));
        mRecyclerView.setAdapter(new PlaceVisitAdapter(DummyContent.ITEMS, mListener));
        mUsername.setText("Change Me. Please");
        Utils.setupSupportToolbar(getActivity(), mToolbar, "Profil", true);
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
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    interface ProfileStatsListener {
        // TODO: Update argument type and name
        void onListFragmentInteraction(DummyItem item);
    }
}
