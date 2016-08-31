package no.dnt.sjekkut.ui;

import android.content.Context;
import android.location.Location;
import android.support.v7.widget.RecyclerView;
import android.view.ViewGroup;

import java.util.Collections;

import no.dnt.sjekkut.network.Place;
import no.dnt.sjekkut.network.Project;
import no.dnt.sjekkut.network.UserCheckins;

/**
 * Copyright Den Norske Turistforening 2016
 * <p/>
 * Created by espen on 25.08.2016.
 */
class ProjectPlaceWrapperAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private final ProjectAdapter mProjectAdapter;
    private final ParticipantAdapter mParticipantAdapter;
    private final PlaceAdapter mPlaceAdapter;
    private final int VIEW_TYPE_PROJECT = 0;
    private final int VIEW_TYPE_PARTICIPATING = 1;
    private final int VIEW_TYPE_PLACE = 2;

    ProjectPlaceWrapperAdapter(Context context, PlaceListFragment.PlaceListListener listener) {
        RecyclerView.AdapterDataObserver mAdapterObserver = new RecyclerView.AdapterDataObserver() {
            @Override
            public void onChanged() {
                notifyDataSetChanged();
            }
        };
        mProjectAdapter = new ProjectAdapter(null);
        mProjectAdapter.registerAdapterDataObserver(mAdapterObserver);
        mParticipantAdapter = new ParticipantAdapter();
        mParticipantAdapter.registerAdapterDataObserver(mAdapterObserver);
        mPlaceAdapter = new PlaceAdapter(context, listener);
        mPlaceAdapter.registerAdapterDataObserver(mAdapterObserver);
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        switch (viewType) {
            case VIEW_TYPE_PROJECT:
                return mProjectAdapter.createViewHolder(parent, viewType);
            case VIEW_TYPE_PARTICIPATING:
                return mParticipantAdapter.createViewHolder(parent, viewType);
            default:
                return mPlaceAdapter.createViewHolder(parent, viewType);
        }
    }

    @Override
    public int getItemViewType(int position) {
        if (position < mProjectAdapter.getItemCount()) {
            return VIEW_TYPE_PROJECT;
        } else if (position - mProjectAdapter.getItemCount() < mParticipantAdapter.getItemCount()) {
            return VIEW_TYPE_PARTICIPATING;
        } else {
            return VIEW_TYPE_PLACE;
        }
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {
        switch (getItemViewType(position)) {
            case VIEW_TYPE_PROJECT:
                mProjectAdapter.onBindViewHolder((ProjectAdapter.ProjectHolder) holder, position);
                break;
            case VIEW_TYPE_PARTICIPATING:
                mParticipantAdapter.onBindViewHolder((ParticipantAdapter.ParticipantHolder) holder, position - mProjectAdapter.getItemCount());
                break;
            case VIEW_TYPE_PLACE:
                mPlaceAdapter.onBindViewHolder((PlaceAdapter.PlaceViewHolder) holder, position - mParticipantAdapter.getItemCount() - mProjectAdapter.getItemCount());
                break;
        }
    }

    @Override
    public int getItemCount() {
        return mProjectAdapter.getItemCount() + mParticipantAdapter.getItemCount() + mPlaceAdapter.getItemCount();
    }

    void setProjectAndPlaces(Project project) {
        mProjectAdapter.setProjects(Collections.singletonList(project));
        mParticipantAdapter.setProjectIds(Collections.singletonList(project._id));
        mPlaceAdapter.setPlaces(project.steder);

    }

    void updatePlace(Place place) {
        mPlaceAdapter.updatePlace(place);
    }

    void setUserCheckins(UserCheckins userCheckins) {
        mProjectAdapter.setUserCheckins(userCheckins);
        mParticipantAdapter.setUserCheckins(userCheckins);
        mPlaceAdapter.setUserCheckins(userCheckins);
    }

    void setLocation(Location location) {
        mProjectAdapter.setLocation(location);
        mPlaceAdapter.setLocation(location);
    }
}
