package no.dnt.sjekkut.ui;

import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;

import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;

abstract class LocationFragment extends Fragment implements LocationListener {

    public LocationFragment() {
        // Required empty public constructor
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        if (getActivity() instanceof MainActivity) {
            ((MainActivity) getActivity()).startLocationUpdates(this, getLocationRequest());
        }
    }

    private LocationRequest getLocationRequest() {
        return LocationRequestUtils.repeatingRequest();
    }
}
